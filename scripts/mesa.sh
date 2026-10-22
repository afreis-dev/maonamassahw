#!/usr/bin/env bash
set -eu

bin32() {
    local n=$(( $1 & 0xFFFFFFFF )) s="" i
    for ((i = 31; i >= 0; i--)); do
        s+=$(( (n >> i) & 1 ))
    done
    echo "$s"
}

printf '%-6s %-12s %-16s %-34s %s\n' "v[i]" "v[i]>=128" "mascara (dec)" "mascara (bin, 32 bits)" "v[i] & mascara"
for v in 200 50; do
    cond=$(( v >= 128 ))
    mascara=$(( -cond ))
    printf '%-6d %-12d %-16d %-34s %d\n' "$v" "$cond" "$mascara" "$(bin32 "$mascara")" "$(( v & mascara ))"
done
