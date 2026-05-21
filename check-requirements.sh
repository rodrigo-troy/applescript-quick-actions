#!/bin/zsh
# Report, per AppleScript in scripts/, whether its external tool dependencies
# (FFmpeg, ExifTool, sips, Pixelmator Pro) are satisfied on this system.
# Read-only: never installs, never modifies anything.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"

if [[ -z "${NO_COLOR-}" ]]; then
    green=$'\e[32m'; red=$'\e[31m'; yellow=$'\e[33m'
    bold=$'\e[1m'; reset=$'\e[0m'
else
    green=''; red=''; yellow=''; bold=''; reset=''
fi

find_in_paths() {
    local p
    for p in "$@"; do
        if [[ -x "$p" ]]; then
            print -r -- "$p"
            return 0
        fi
    done
    return 1
}

ffmpeg_path="$(find_in_paths /opt/homebrew/bin/ffmpeg /usr/local/bin/ffmpeg /usr/bin/ffmpeg)"
exiftool_path="$(find_in_paths /opt/homebrew/bin/exiftool /usr/local/bin/exiftool /usr/bin/exiftool)"
sips_path="$(find_in_paths /usr/bin/sips)"

if [[ -d "/Applications/Pixelmator Pro.app" ]]; then
    pixelmator_path="/Applications/Pixelmator Pro.app"
else
    pixelmator_path=""
fi

tool_row() {
    local color="$1" sym="$2" name="$3" path="$4"
    if [[ -n "$path" ]]; then
        printf '   %s%s%s %-16s %s\n' "$color" "$sym" "$reset" "$name" "$path"
    else
        printf '   %s%s%s %-16s %s\n' "$color" "$sym" "$reset" "$name" "not found"
    fi
}

print -r -- "${bold}External tools${reset}"
[[ -n "$ffmpeg_path"     ]] && tool_row "$green" "✓" "FFmpeg"         "$ffmpeg_path"     || tool_row "$red" "✗" "FFmpeg"         ""
[[ -n "$exiftool_path"   ]] && tool_row "$green" "✓" "ExifTool"       "$exiftool_path"   || tool_row "$red" "✗" "ExifTool"       ""
[[ -n "$sips_path"       ]] && tool_row "$green" "✓" "sips"           "$sips_path"       || tool_row "$red" "✗" "sips"           ""
[[ -n "$pixelmator_path" ]] && tool_row "$green" "✓" "Pixelmator Pro" "$pixelmator_path" || tool_row "$red" "✗" "Pixelmator Pro" ""

script_lines=()
script_syms=()
script_colors=()
ready=0
blocked=0
no_deps=0

need_brew_ffmpeg=0
need_brew_exiftool=0
need_pixelmator=0
need_sips=0

max_name_width=0
for f in "$SCRIPT_DIR"/*.applescript(N); do
    [[ -f "$f" ]] || continue
    bn="$(basename "$f" .applescript)"
    (( ${#bn} > max_name_width )) && max_name_width=${#bn}
done

name_col=$(( max_name_width + 2 ))

for f in "$SCRIPT_DIR"/*.applescript(N); do
    [[ -f "$f" ]] || continue
    bn="$(basename "$f" .applescript)"

    uses_ffmpeg=0;     grep -qi    ffmpeg                            "$f" && uses_ffmpeg=1
    uses_exiftool=0;   grep -qi    exiftool                          "$f" && uses_exiftool=1
    uses_sips=0;       grep -qwi   sips                              "$f" && uses_sips=1
    uses_pixelmator=0; grep -qF    'application "Pixelmator Pro"'    "$f" && uses_pixelmator=1

    total_deps=$(( uses_ffmpeg + uses_exiftool + uses_sips + uses_pixelmator ))

    present_list=()
    missing_list=()

    if (( uses_ffmpeg )); then
        [[ -n "$ffmpeg_path"   ]] && present_list+=("ffmpeg")   || { missing_list+=("ffmpeg");   need_brew_ffmpeg=1; }
    fi

    if (( uses_exiftool )); then
        [[ -n "$exiftool_path" ]] && present_list+=("exiftool") || { missing_list+=("exiftool"); need_brew_exiftool=1; }
    fi

    if (( uses_sips )); then
        [[ -n "$sips_path"     ]] && present_list+=("sips")     || { missing_list+=("sips");     need_sips=1; }
    fi

    if (( uses_pixelmator )); then
        [[ -n "$pixelmator_path" ]] && present_list+=("Pixelmator Pro") || { missing_list+=("Pixelmator Pro"); need_pixelmator=1; }
    fi

    if (( total_deps == 0 )); then
        script_syms+=("⊘"); script_colors+=("$yellow")
        script_lines+=("$bn|(no external deps)")
        (( ++no_deps ))
    elif (( ${#missing_list[@]} == 0 )); then
        present_joined="${(j:, :)present_list}"
        script_syms+=("✓"); script_colors+=("$green")
        script_lines+=("$bn|($present_joined)")
        (( ++ready ))
    else
        missing_joined="${(j:, :)missing_list}"
        script_syms+=("✗"); script_colors+=("$red")
        script_lines+=("$bn|(needs: $missing_joined)")
        (( ++blocked ))
    fi
done

print -r -- ""
print -r -- "${bold}Scripts${reset}"
for (( i = 1; i <= ${#script_lines[@]}; i++ )); do
    entry="${script_lines[$i]}"
    bn="${entry%%|*}"
    paren="${entry#*|}"
    printf ' %s%s%s  %-*s %s\n' "${script_colors[$i]}" "${script_syms[$i]}" "$reset" "$name_col" "$bn" "$paren"
done

print -r -- ""
print -r -- "Results: $ready ready, $blocked blocked, $no_deps no-deps"

if (( blocked > 0 )); then
    print -r -- ""
    print -r -- "${bold}Install missing:${reset}"

    brew_pkgs=()
    (( need_brew_ffmpeg   )) && brew_pkgs+=("ffmpeg")
    (( need_brew_exiftool )) && brew_pkgs+=("exiftool")

    if (( ${#brew_pkgs[@]} > 0 )); then
        printf '   brew install %s\n' "${(j: :)brew_pkgs}"
    fi

    if (( need_pixelmator )); then
        print -r -- "   Install Pixelmator Pro from the Mac App Store or pixelmator.com/pro"
    fi

    if (( need_sips )); then
        print -r -- "   sips is part of macOS — verify your /usr/bin is intact"
    fi

    exit 1
fi
exit 0
