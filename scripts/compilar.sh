#!/usr/bin/env bash
set -eu
. "$(dirname "$0")/comum.sh"
cd "$RAIZ"

gcc -O1 -Wall -o "$BIN/branch" branch.c
gcc -O1 -Wall -o "$BIN/branchless" branchless.c
gcc -O1 -Wall -DLIMIAR=250 -o "$BIN/branch250" branch.c
gcc -O1 -Wall -DLIMIAR=250 -o "$BIN/branchless250" branchless.c
gcc -O1 -DSEM_BARREIRA -o "$BIN/branch_esperto" branch.c
gcc -O2 -DSEM_BARREIRA -o "$BIN/branch_esperto_O2" branch.c

gcc -O1 -DSEM_BARREIRA -S -o "$SAIDA/asm/esperto.s" branch.c
gcc -O1 -S -o "$SAIDA/asm/com_barreira.s" branch.c
gcc -O2 -DSEM_BARREIRA -S -o "$SAIDA/asm/esperto_O2.s" branch.c
gcc -O1 -S -o "$SAIDA/asm/branchless.s" branchless.c

echo "binarios em $BIN"
