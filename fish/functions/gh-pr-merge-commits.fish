function gh-pr-merge-commits --description "Get merge commit SHA(s) for GitHub PRs"
    argparse h/help a/author= b/base= r/repo= H/host= n/limit= u/show-url force-color no-color -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage:"
        echo "  gh-pr-merge-commits"
        echo "  gh-pr-merge-commits <pr-number>"
        echo "  gh-pr-merge-commits <pr-url>"
        echo "  gh-pr-merge-commits <owner/repo>"
        echo "  gh-pr-merge-commits <owner/repo> <pr-number|#pr-number>"
        echo
        echo "Options:"
        echo "  -a, --author <author>   Author filter for list mode (default: @me)"
        echo "  -b, --base <branch>     Base branch for list mode (default: master)"
        echo "  -r, --repo <owner/repo> Repo override (default: current git repo)"
        echo "  -H, --host <host>       GitHub host override (default: current git host)"
        echo "  -n, --limit <n>         Max merged PRs to return in list mode (default: 50)"
        echo "  -u, --show-url          Include PR URL column"
        echo "      --force-color       Force ANSI colors even if output is not a TTY"
        echo "      --no-color          Disable ANSI colors"
        return 0
    end

    set -l author "@me"
    set -l base "master"
    set -l limit 50
    set -l show_url 0
    set -l tab (printf '\t')
    set -l color_enabled 1
    set -l c_reset ""
    set -l c_header ""
    set -l c_meta ""
    set -l c_warn ""
    set -l c_pr ""
    set -l c_sha ""
    set -l c_time ""
    set -l c_row_odd ""
    set -l c_row_even ""

    if set -q _flag_author
        set author $_flag_author
    end
    if set -q _flag_base
        set base $_flag_base
    end
    if set -q _flag_limit
        if not string match -qr '^[1-9][0-9]*$' -- $_flag_limit
            echo "Invalid limit: $_flag_limit (expected positive integer)" >&2
            return 1
        end
        set limit $_flag_limit
    end
    if set -q _flag_show_url
        set show_url 1
    end

    if set -q _flag_no_color
        set color_enabled 0
    else if not isatty stdout
        if not set -q _flag_force_color
            set color_enabled 0
        end
    else if set -q NO_COLOR
        if not set -q _flag_force_color
            set color_enabled 0
        end
    end

    if test "$color_enabled" -eq 1
        set c_reset "\e[0m"
        set c_header "\e[1;96m"
        set c_meta "\e[1;90m"
        set c_warn "\e[1;33m"
        set c_pr "\e[1;36m"
        set c_sha "\e[2;37m"
        set c_time "\e[38;5;110m"
        set c_row_odd "\e[38;5;252m"
        set c_row_even "\e[38;5;248m"
    end

    set -l remote (git remote get-url origin 2>/dev/null)
    if test -z "$remote"
        echo "Unable to resolve origin remote in current directory" >&2
        return 1
    end

    set -l default_host
    set -l default_repo
    if string match -qr '^git@' -- $remote
        set default_host (string replace -r '^git@([^:]+):.*$' '$1' -- $remote)
        set default_repo (string replace -r '^git@[^:]+:(.*)$' '$1' -- $remote)
    else if string match -qr '^https?://' -- $remote
        set default_host (string replace -r '^https?://([^/]+)/.*$' '$1' -- $remote)
        set default_repo (string replace -r '^https?://[^/]+/(.*)$' '$1' -- $remote)
    else
        echo "Unsupported origin remote format: $remote" >&2
        return 1
    end
    set default_repo (string replace -r '\.git$' '' -- $default_repo)

    set -l host $default_host
    set -l repo $default_repo
    set -l pr ""

    if set -q _flag_host
        set host $_flag_host
    end
    if set -q _flag_repo
        set repo $_flag_repo
    end

    switch (count $argv)
        case 0
            # List mode: use default host/repo and filters.
        case 1
            set -l arg $argv[1]
            if string match -qr '^https?://[^/]+/[^/]+/[^/]+/pull/[0-9]+' -- $arg
                set host (string replace -r '^https?://([^/]+)/.*$' '$1' -- $arg)
                set repo (string replace -r '^https?://[^/]+/([^/]+/[^/]+)/pull/[0-9]+.*$' '$1' -- $arg)
                set pr (string replace -r '^.*/pull/([0-9]+).*$' '$1' -- $arg)
            else if string match -qr '^[0-9]+$' -- $arg
                set pr $arg
            else if string match -qr '^[^/]+/[^/]+$' -- $arg
                set repo $arg
            else if string match -qr '^[^/]+/[^#]+#[0-9]+$' -- $arg
                set repo (string replace -r '#[0-9]+$' '' -- $arg)
                set pr (string replace -r '^.*#([0-9]+)$' '$1' -- $arg)
            else
                echo "Invalid argument: $arg" >&2
                echo "Run 'gh-pr-merge-commits --help' for usage." >&2
                return 1
            end
        case 2
            set repo $argv[1]
            set pr (string replace -r '^#' '' -- $argv[2])

            if not string match -qr '^[^/]+/[^/]+$' -- $repo
                echo "Invalid repo format: $repo (expected owner/repo)" >&2
                return 1
            end
            if not string match -qr '^[0-9]+$' -- $pr
                echo "Invalid PR number: $argv[2]" >&2
                return 1
            end
        case '*'
            echo "Too many arguments." >&2
            echo "Run 'gh-pr-merge-commits --help' for usage." >&2
            return 1
    end

    if not string match -qr '^[^/]+/[^/]+$' -- $repo
        echo "Invalid repo format: $repo (expected owner/repo)" >&2
        return 1
    end

    if test -n "$pr"
        set -l pr_json (gh api --hostname "$host" "repos/$repo/pulls/$pr")
        or return $status

        set -l merged_at (printf '%s\n' "$pr_json" | jq -r '.merged_at // empty')
        if test -z "$merged_at"
            echo "PR $repo#$pr is not merged yet; no final merge commit is available." >&2
            return 1
        end

        set -l header
        set -l row
        if test "$show_url" -eq 1
            set row (printf '%s\n' "$pr_json" | jq -r '[.number,.merge_commit_sha,.title,.html_url,.merged_at] | @tsv')
        else
            set row (printf '%s\n' "$pr_json" | jq -r '[.number,.merge_commit_sha,.title,.merged_at] | @tsv')
        end

        if test "$show_url" -eq 1
            printf '%b%-8s %-40s %-72s %-56s %-20s%b\n' "$c_header" "PR" "MERGE_SHA" "TITLE" "URL" "MERGED_AT" "$c_reset"

            set -l cols (string split $tab -- "$row")
            set -l title $cols[3]
            set -l url $cols[4]
            set -l row_tint $c_row_odd
            if test (string length -- "$title") -gt 72
                set title (string sub -s 1 -l 69 -- "$title")"..."
            end
            if test (string length -- "$url") -gt 56
                set url (string sub -s 1 -l 53 -- "$url")"..."
            end
            printf '%b%-8s%b %b%-40s%b %b%-72s%b %b%-56s%b %b%-20s%b\n' \
                "$c_pr" "$cols[1]" "$row_tint" \
                "$c_sha" "$cols[2]" "$row_tint" \
                "$row_tint" "$title" "$row_tint" \
                "$row_tint" "$url" "$row_tint" \
                "$c_time" "$cols[5]" "$c_reset"
        else
            printf '%b%-8s %-40s %-96s %-20s%b\n' "$c_header" "PR" "MERGE_SHA" "TITLE" "MERGED_AT" "$c_reset"

            set -l cols (string split $tab -- "$row")
            set -l title $cols[3]
            set -l row_tint $c_row_odd
            if test (string length -- "$title") -gt 96
                set title (string sub -s 1 -l 93 -- "$title")"..."
            end
            printf '%b%-8s%b %b%-40s%b %b%-96s%b %b%-20s%b\n' \
                "$c_pr" "$cols[1]" "$row_tint" \
                "$c_sha" "$cols[2]" "$row_tint" \
                "$row_tint" "$title" "$row_tint" \
                "$c_time" "$cols[4]" "$c_reset"
        end
        return $status
    end

    set -l prs_json (
        gh pr list \
        --repo "$host/$repo" \
        --state merged \
        --search "author:$author is:merged base:$base" \
        --limit "$limit" \
        --json number,title,mergedAt,mergeCommit,url
    )
    or return $status

    set -l rows
    if test "$show_url" -eq 1
        set rows (printf '%s\n' "$prs_json" | jq -r '.[] | [.number, .mergeCommit.oid, .title, .url, .mergedAt] | @tsv')
    else
        set rows (printf '%s\n' "$prs_json" | jq -r '.[] | [.number, .mergeCommit.oid, .title, .mergedAt] | @tsv')
    end

    if test -z "$rows"
        printf '%bNo merged PRs found for %s/%s (author: %s, base: %s)%b\n' "$c_warn" "$host" "$repo" "$author" "$base" "$c_reset"
        return 0
    end

    printf '%bRepo: %s/%s  Author: %s  Base: %s  Limit: %s%b\n' "$c_meta" "$host" "$repo" "$author" "$base" "$limit" "$c_reset"

    if test "$show_url" -eq 1
        printf '%b%-8s %-40s %-72s %-56s %-20s%b\n' "$c_header" "PR" "MERGE_SHA" "TITLE" "URL" "MERGED_AT" "$c_reset"

        set -l idx 0
        for row in $rows
            set idx (math $idx + 1)
            set -l cols (string split $tab -- "$row")
            set -l title $cols[3]
            set -l url $cols[4]
            set -l row_tint $c_row_even
            if test (math "$idx % 2") -eq 1
                set row_tint $c_row_odd
            end
            if test (string length -- "$title") -gt 72
                set title (string sub -s 1 -l 69 -- "$title")"..."
            end
            if test (string length -- "$url") -gt 56
                set url (string sub -s 1 -l 53 -- "$url")"..."
            end
            printf '%b%-8s%b %b%-40s%b %b%-72s%b %b%-56s%b %b%-20s%b\n' \
                "$c_pr" "$cols[1]" "$row_tint" \
                "$c_sha" "$cols[2]" "$row_tint" \
                "$row_tint" "$title" "$row_tint" \
                "$row_tint" "$url" "$row_tint" \
                "$c_time" "$cols[5]" "$c_reset"
        end
    else
        printf '%b%-8s %-40s %-96s %-20s%b\n' "$c_header" "PR" "MERGE_SHA" "TITLE" "MERGED_AT" "$c_reset"

        set -l idx 0
        for row in $rows
            set idx (math $idx + 1)
            set -l cols (string split $tab -- "$row")
            set -l title $cols[3]
            set -l row_tint $c_row_even
            if test (math "$idx % 2") -eq 1
                set row_tint $c_row_odd
            end
            if test (string length -- "$title") -gt 96
                set title (string sub -s 1 -l 93 -- "$title")"..."
            end
            printf '%b%-8s%b %b%-40s%b %b%-96s%b %b%-20s%b\n' \
                "$c_pr" "$cols[1]" "$row_tint" \
                "$c_sha" "$cols[2]" "$row_tint" \
                "$row_tint" "$title" "$row_tint" \
                "$c_time" "$cols[4]" "$c_reset"
        end
    end
end
