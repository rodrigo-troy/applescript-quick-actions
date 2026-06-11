#!/bin/zsh
# Compile all AppleScript files in the scripts/ directory to check for syntax errors.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"
err_log="$(mktemp -t osacompile_err)"
trap 'rm -f "$err_log"' EXIT

if [[ -z "${NO_COLOR-}" ]]; then
    green=$'\e[32m'; red=$'\e[31m'; yellow=$'\e[33m'
    bold=$'\e[1m'; reset=$'\e[0m'
else
    green=''; red=''; yellow=''; bold=''; reset=''
fi

has_pixelmator_pro=0
[ -d "/Applications/Pixelmator Pro.app" ] && has_pixelmator_pro=1

passed=0
failed=0
skipped=0
errors=()

for f in "$SCRIPT_DIR"/*.applescript; do
    [ -f "$f" ] || continue
    name="${f:t}"

    if (( ! has_pixelmator_pro )) && grep -q 'application "Pixelmator Pro"' "$f"; then
        print -r -- " ${yellow}⊘${reset}  $name (Pixelmator Pro not installed)"
        (( ++skipped ))
        continue
    fi

    if osacompile -o /dev/null "$f" 2>"$err_log"; then
        print -r -- " ${green}✓${reset}  $name"
        (( ++passed ))
    else
        print -r -- " ${red}✗${reset}  $name"
        errors+=("$name"$'\n'"$(<"$err_log")")
        (( ++failed ))
    fi
done

print "\nResults: $passed passed, $failed failed, $skipped skipped"

if [ ${#errors[@]} -gt 0 ]; then
    print "\n${bold}Errors:${reset}"

    for err in "${errors[@]}"; do
        err_name="${err%%$'\n'*}"
        err_body="${err#*$'\n'}"
        print -r -- " ${red}✗${reset}  $err_name"
        [[ -n "$err_body" ]] && print -r -- "$err_body" | sed 's/^/    /'
    done

    exit 1
fi
