import AppKit
import CoreServices
import Foundation
import UniformTypeIdentifiers

let defaultExtensions: [String] = [
  // Markdown & prose
  "md", "markdown", "mdx", "txt",
  // Config & data
  "json", "jsonc", "toml", "yaml", "yml", "ini", "conf", "env", "xml",
  // Shell & scripting
  "lua", "sh", "bash", "zsh", "fish",
  // Languages
  "py", "rb", "go", "rs",
  "js", "jsx", "ts", "tsx", "mjs", "cjs", "astro", "css", "scss", "sql", "graphql", "proto",
  "kt", "kts", "java", "gradle",
  "c", "h", "cpp", "hpp", "m", "mm", "swift",
]

let extraUTTypes: [String] = [
  "net.daringfireball.markdown",
  "public.plain-text",
  "public.json",
  "public.yaml",
  "public.shell-script",
  "public.python-script",
  "public.ruby-script",
  "public.swift-source",
  "public.c-source",
  "public.c-header",
  "public.c-plus-plus-source",
  "public.objective-c-source",
]

func findRexBinary() -> String? {
  let home = FileManager.default.homeDirectoryForCurrentUser.path
  let candidates = [
    "\(home)/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex",
    "/opt/homebrew/bin/rex",
    "/usr/local/bin/rex",
  ]
  for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
    return path
  }
  return nil
}

func activateRexApp() {
  let appPaths = [
    "/Applications/Rex Beta.app",
    "/Applications/Rex.app",
  ]
  for path in appPaths where FileManager.default.fileExists(atPath: path) {
    let url = URL(fileURLWithPath: path)
    let config = NSWorkspace.OpenConfiguration()
    config.activates = true
    NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
    return
  }
}

func parseLine(from fragment: String?) -> String? {
  guard let fragment, !fragment.isEmpty else { return nil }
  let trimmed = fragment.hasPrefix("L") ? String(fragment.dropFirst()) : fragment
  let digits = trimmed.prefix { $0.isNumber }
  return digits.isEmpty ? nil : String(digits)
}

func isRexFrontmost() -> Bool {
  guard let front = NSWorkspace.shared.frontmostApplication else { return false }
  if let bundleID = front.bundleIdentifier, bundleID.localizedCaseInsensitiveContains("superlogical.rex") {
    return true
  }
  if let name = front.localizedName, name.localizedCaseInsensitiveContains("rex") {
    return true
  }
  return false
}

func resolveDefaultMode(explicitMode: String?, fromRex: Bool) -> String {
  if let explicitMode, !explicitMode.isEmpty {
    return explicitMode
  }
  if NSEvent.modifierFlags.contains(.option) {
    return "pick"
  }
  return fromRex ? "split" : "tab"
}

func openInRex(urls: [URL], mode: String) {
  guard let rexPath = findRexBinary() else {
    fputs("rex-neovim: could not locate rex CLI binary\n", stderr)
    return
  }

  activateRexApp()

  for url in urls {
    guard url.isFileURL else { continue }
    let filePath = url.path
    var payload: [String: String] = ["path": filePath, "mode": mode]
    if let line = parseLine(from: url.fragment) {
      payload["line"] = line
    }
    guard let data = try? JSONSerialization.data(withJSONObject: payload),
          let json = String(data: data, encoding: .utf8)
    else { continue }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: rexPath)
    process.arguments = ["do", "open_file", "--args", json]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      fputs("rex-neovim: failed to invoke rex: \(error)\n", stderr)
    }
  }
}

func registerDefaults(bundleID: String) -> Int32 {
  var seen = Set<String>()
  var identifiers: [String] = []

  for identifier in extraUTTypes {
    if seen.insert(identifier).inserted {
      identifiers.append(identifier)
    }
  }
  for ext in defaultExtensions {
    let textTypes = UTType.types(tag: ext, tagClass: .filenameExtension, conformingTo: .text)
    let matched = textTypes.isEmpty ? UTType(filenameExtension: ext).map { [$0] } ?? [] : textTypes
    for type in matched where seen.insert(type.identifier).inserted {
      identifiers.append(type.identifier)
    }
  }

  var failures = 0
  for identifier in identifiers {
    let status = LSSetDefaultRoleHandlerForContentType(identifier as CFString, .all, bundleID as CFString)
    if status != noErr {
      failures += 1
      fputs("warn: \(identifier): OSStatus \(status)\n", stderr)
    }
  }

  print("Registered \(bundleID) for \(identifiers.count - failures)/\(identifiers.count) file types")
  return failures == 0 ? 0 : 1
}

class AppDelegate: NSObject, NSApplicationDelegate {
  private var handledFiles = false
  private let launchedFromRex: Bool

  init(launchedFromRex: Bool) {
    self.launchedFromRex = launchedFromRex
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    handledFiles = true
    let mode = resolveDefaultMode(explicitMode: nil, fromRex: launchedFromRex)
    openInRex(urls: urls, mode: mode)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      NSApp.terminate(nil)
    }
  }

  func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    handledFiles = true
    let mode = resolveDefaultMode(explicitMode: nil, fromRex: launchedFromRex)
    openInRex(urls: [URL(fileURLWithPath: filename)], mode: mode)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      NSApp.terminate(nil)
    }
    return true
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Allow Launch Services a brief moment to deliver open-file AppleEvents.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
      if !self.handledFiles {
        activateRexApp()
        NSApp.terminate(nil)
      }
    }
  }
}

let launchedFromRex = isRexFrontmost()
let args = Array(CommandLine.arguments.dropFirst())
if args.first == "--register" {
  let bundleID = Bundle.main.bundleIdentifier ?? "com.iheanyi.rex-neovim"
  exit(registerDefaults(bundleID: bundleID))
}

var explicitMode: String?
var cliPaths: [String] = []
var index = 0
while index < args.count {
  let arg = args[index]
  if arg == "--mode", index + 1 < args.count {
    explicitMode = args[index + 1]
    index += 2
  } else if arg.hasPrefix("--mode=") {
    explicitMode = String(arg.dropFirst("--mode=".count))
    index += 1
  } else if arg.hasPrefix("-") {
    index += 1
  } else {
    cliPaths.append(arg)
    index += 1
  }
}

if !cliPaths.isEmpty {
  let urls = cliPaths.map { arg -> URL in
    if arg.hasPrefix("file://"), let parsed = URL(string: arg) {
      return parsed
    }
    return URL(fileURLWithPath: (arg as NSString).expandingTildeInPath)
  }
  let mode = resolveDefaultMode(explicitMode: explicitMode, fromRex: launchedFromRex)
  openInRex(urls: urls, mode: mode)
  exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate(launchedFromRex: launchedFromRex)
app.delegate = delegate
app.run()
