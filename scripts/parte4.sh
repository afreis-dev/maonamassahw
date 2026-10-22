#!/usr/bin/env bash
set -eu
. "$(dirname "$0")/comum.sh"
bash "$(dirname "$0")/compilar.sh" >/dev/null

bash "$(dirname "$0")/mesa.sh" | tee "$SAIDA/parte4_teste_de_mesa.txt"

{
    echo "### execucao unica de cada modo"
    "$BIN/branchless" aleatorio "$REP"
    "$BIN/branchless" sort "$REP"
    echo
    echo "### medir.sh"
    bash "$RAIZ/medir.sh" "$BIN/branchless" "$REP"
} 2>&1 | tee "$SAIDA/parte4_branchless.txt"

{
    echo "### branch_esperto (-O1 -DSEM_BARREIRA)"
    bash "$RAIZ/medir.sh" "$BIN/branch_esperto" "$REP"
    echo "### branch_esperto_O2 (-O2 -DSEM_BARREIRA)"
    bash "$RAIZ/medir.sh" "$BIN/branch_esperto_O2" "$REP"
} 2>&1 | tee "$SAIDA/parte4_esperto.txt"

bash "$(dirname "$0")/trechos.sh" | tee "$SAIDA/parte4_trechos_asm.txt"
