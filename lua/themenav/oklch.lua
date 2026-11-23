-- Pure-Lua OKLCH color math, sRGB gamut clamping, and APCA-W3 perceptual contrast.
local M = {}

local abs = math.abs
local atan2 = math.atan2
local cos = math.cos
local floor = math.floor
local max = math.max
local min = math.min
local pi = math.pi
local sin = math.sin
local sqrt = math.sqrt

local DEG2RAD = pi / 180
local RAD2DEG = 180 / pi

local function clamp(x, lo, hi)
  if x < lo then
    return lo
  end
  if x > hi then
    return hi
  end
  return x
end

local function cbrt(x)
  if x < 0 then
    return -((-x) ^ (1 / 3))
  end
  return x ^ (1 / 3)
end

local function srgb_to_linear(c)
  if c <= 0.04045 then
    return c / 12.92
  end
  return ((c + 0.055) / 1.055) ^ 2.4
end

local function linear_to_srgb(c)
  if c <= 0.0031308 then
    return 12.92 * c
  end
  return 1.055 * (c ^ (1 / 2.4)) - 0.055
end

function M.wrap_hue(h)
  h = h % 360
  if h < 0 then
    h = h + 360
  end
  return h
end

function M.hex_to_rgb(hex)
  if type(hex) ~= "string" then
    return 0, 0, 0
  end
  local clean = hex:gsub("^#", "")
  if #clean == 3 then
    clean = clean:sub(1, 1):rep(2) .. clean:sub(2, 2):rep(2) .. clean:sub(3, 3):rep(2)
  end
  if #clean ~= 6 then
    return 0, 0, 0
  end
  local r = tonumber(clean:sub(1, 2), 16) or 0
  local g = tonumber(clean:sub(3, 4), 16) or 0
  local b = tonumber(clean:sub(5, 6), 16) or 0
  return r / 255, g / 255, b / 255
end

function M.rgb_to_hex(r, g, b)
  local ri = floor(clamp(r, 0, 1) * 255 + 0.5)
  local gi = floor(clamp(g, 0, 1) * 255 + 0.5)
  local bi = floor(clamp(b, 0, 1) * 255 + 0.5)
  return string.format("#%02x%02x%02x", ri, gi, bi)
end

function M.rgb_to_oklab(r, g, b)
  local lr = srgb_to_linear(clamp(r, 0, 1))
  local lg = srgb_to_linear(clamp(g, 0, 1))
  local lb = srgb_to_linear(clamp(b, 0, 1))

  local l = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb
  local m = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb
  local s = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb

  local l_ = cbrt(l)
  local m_ = cbrt(m)
  local s_ = cbrt(s)

  local L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
  local a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
  local b_ = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
  return L, a, b_
end

function M.oklab_to_linear_rgb(L, a, b)
  local l_ = L + 0.3963377774 * a + 0.2158037573 * b
  local m_ = L - 0.1055613458 * a - 0.0638541728 * b
  local s_ = L - 0.0894841775 * a - 1.2914855480 * b

  local l = l_ * l_ * l_
  local m = m_ * m_ * m_
  local s = s_ * s_ * s_

  local r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
  local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
  local b_ = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
  return r, g, b_
end

function M.oklab_to_rgb(L, a, b)
  local lr, lg, lb = M.oklab_to_linear_rgb(L, a, b)
  return linear_to_srgb(clamp(lr, 0, 1)), linear_to_srgb(clamp(lg, 0, 1)), linear_to_srgb(clamp(lb, 0, 1))
end

function M.hex_to_oklch(hex)
  local r, g, b = M.hex_to_rgb(hex)
  local L, a, b_ = M.rgb_to_oklab(r, g, b)
  local C = sqrt(a * a + b_ * b_)
  local H = C < 1e-6 and 0 or M.wrap_hue(atan2(b_, a) * RAD2DEG)
  return L, C, H
end

local function in_srgb_linear(r, g, b)
  local eps = 1e-5
  return r >= -eps and r <= 1 + eps and g >= -eps and g <= 1 + eps and b >= -eps and b <= 1 + eps
end

--- Maximum displayable sRGB chroma at lightness L and hue H (degrees).
function M.max_chroma(L, H)
  L = clamp(L, 0, 1)
  if L <= 0.0001 or L >= 0.9999 then
    return 0
  end
  local rad = H * DEG2RAD
  local ca = cos(rad)
  local sb = sin(rad)
  local lo, hi = 0.0, 0.40
  for _ = 1, 16 do
    local mid = (lo + hi) * 0.5
    local r, g, b = M.oklab_to_linear_rgb(L, mid * ca, mid * sb)
    if in_srgb_linear(r, g, b) then
      lo = mid
    else
      hi = mid
    end
  end
  return lo
end

--- Convert OKLCH to hex, clamping chroma smoothly into sRGB while preserving L and H.
function M.oklch_to_hex(L, C, H)
  L = clamp(L, 0, 1)
  C = max(0, C)
  H = M.wrap_hue(H)
  local rad = H * DEG2RAD
  local a = C * cos(rad)
  local b = C * sin(rad)
  local lr, lg, lb = M.oklab_to_linear_rgb(L, a, b)
  if not in_srgb_linear(lr, lg, lb) then
    local capped = M.max_chroma(L, H)
    a = capped * cos(rad)
    b = capped * sin(rad)
  end
  local r, g, b_ = M.oklab_to_rgb(L, a, b)
  return M.rgb_to_hex(r, g, b_)
end

--- Convert OKLCH using a fraction (0..1) of the hue's sRGB chroma ceiling at lightness L.
--- Sibling colors with the same L and ratio look equally vivid across all hues.
function M.relative_oklch(L, chroma_ratio, H, max_abs_c)
  L = clamp(L, 0, 1)
  H = M.wrap_hue(H)
  local ceiling = M.max_chroma(L, H)
  local C = ceiling * clamp(chroma_ratio, 0, 1)
  if max_abs_c and C > max_abs_c then
    C = max_abs_c
  end
  return M.oklch_to_hex(L, C, H)
end

--- Perceptually uniform OKLab mix between two hex colors (t = 0 -> hex1, t = 1 -> hex2).
function M.mix(hex1, hex2, t)
  t = clamp(t, 0, 1)
  local r1, g1, b1 = M.hex_to_rgb(hex1)
  local r2, g2, b2 = M.hex_to_rgb(hex2)
  local L1, a1, b1_ = M.rgb_to_oklab(r1, g1, b1)
  local L2, a2, b2_ = M.rgb_to_oklab(r2, g2, b2)
  local L = L1 + (L2 - L1) * t
  local a = a1 + (a2 - a1) * t
  local b = b1_ + (b2_ - b1_) * t
  local r, g, b_ = M.oklab_to_rgb(L, a, b)
  return M.rgb_to_hex(r, g, b_)
end

--- APCA-W3 perceptual lightness contrast (signed Lc; magnitude 0..108).
--- Positive for dark text on light background, negative for light text on dark background.
function M.apca(fg_hex, bg_hex)
  local fr, fg, fb = M.hex_to_rgb(fg_hex)
  local br, bg, bb = M.hex_to_rgb(bg_hex)

  local y_txt = 0.2126729 * (fr ^ 2.4) + 0.7151522 * (fg ^ 2.4) + 0.0721750 * (fb ^ 2.4)
  local y_bg = 0.2126729 * (br ^ 2.4) + 0.7151522 * (bg ^ 2.4) + 0.0721750 * (bb ^ 2.4)

  if y_txt < 0.022 then
    y_txt = y_txt + (0.022 - y_txt) ^ 1.414
  end
  if y_bg < 0.022 then
    y_bg = y_bg + (0.022 - y_bg) ^ 1.414
  end

  if abs(y_bg - y_txt) < 0.0005 then
    return 0
  end

  if y_bg > y_txt then
    local sapc = (y_bg ^ 0.56 - y_txt ^ 0.57) * 1.14
    if sapc < 0.1 then
      return 0
    end
    return (sapc - 0.027) * 100
  else
    local sapc = (y_bg ^ 0.65 - y_txt ^ 0.62) * 1.14
    if sapc > -0.1 then
      return 0
    end
    return (sapc + 0.027) * 100
  end
end

function M.apca_abs(fg_hex, bg_hex)
  return abs(M.apca(fg_hex, bg_hex))
end

--- Repair contrast by adjusting ONLY L while preserving C (gamut-clamped) and H.
--- polarity: "dark" (push L up) or "light" (push L down).
function M.ensure_contrast(L, C, H, bg_hex, min_lc, polarity)
  L = clamp(L, 0, 1)
  local hex = M.oklch_to_hex(L, C, H)
  if M.apca_abs(hex, bg_hex) >= min_lc then
    return hex, L
  end

  local is_dark = polarity == "dark"
  local lo = is_dark and L or 0.04
  local hi = is_dark and 0.98 or L
  local best_L = is_dark and hi or lo

  for _ = 1, 14 do
    local mid = (lo + hi) * 0.5
    local candidate = M.oklch_to_hex(mid, C, H)
    local lc = M.apca_abs(candidate, bg_hex)
    if lc >= min_lc then
      best_L = mid
      if is_dark then
        hi = mid
      else
        lo = mid
      end
    else
      if is_dark then
        lo = mid
      else
        hi = mid
      end
    end
  end

  return M.oklch_to_hex(best_L, C, H), best_L
end

return M
