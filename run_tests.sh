#!/usr/bin/env bash
set -euo pipefail

TESTDIR="$1"
ZIGCLI="./zig-out/bin/zmime"

success=0
fail=0

printf "Running tests in %s\n\n" "$TESTDIR"

for testfile in "$TESTDIR"/*.testfile; do
    [ -e "$testfile" ] || continue

    base=$(basename "$testfile" .testfile)

    file_output=$(file -i "$testfile")
    file_mime=$(printf "%s" "$file_output" | sed -E 's/.*: *([^;]+).*/\1/') 

    zmime_output=$("$ZIGCLI" "$testfile" 2>&1)
    zmime_mime=$(printf "%s" "$zmime_output" | head -n 1 | sed -E 's/.*MIME: *([^ ]+).*/\1/')

    if [ "$file_mime" = "$zmime_mime" ]; then 
        printf "✔ %s — OK (%s)\n" "$base" "$file_mime" 
        success=$((success + 1)) 
    else 
        printf "✘ %s — FAIL\n" "$base" 
        printf " file : %s\n" "$file_mime" 
        printf " zmime: %s\n" "$zmime_mime" 
        fail=$((fail + 1)) 
    fi 
done

printf "\nSummary:\n" 
printf " Success: %d\n" "$success" 
printf " Failures: %d\n" "$fail" 
