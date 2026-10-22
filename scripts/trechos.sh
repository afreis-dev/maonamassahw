#!/usr/bin/env bash
set -eu
. "$(dirname "$0")/comum.sh"

for f in com_barreira esperto esperto_O2 branchless; do
    echo "=== $f.s"
    awk '{ l[NR] = $0 } /cmpl[ \t]+\$12[78]/ && !achou { achou = NR } END { for (i = achou - 5; i <= achou + 6; i++) print l[i] }' "$SAIDA/asm/$f.s"
    echo
done
