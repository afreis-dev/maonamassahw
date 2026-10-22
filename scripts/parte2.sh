#!/usr/bin/env bash
set -eu
. "$(dirname "$0")/comum.sh"
bash "$(dirname "$0")/compilar.sh" >/dev/null

{
    echo "### execucao unica de cada modo"
    "$BIN/branch" aleatorio "$REP"
    "$BIN/branch" sort "$REP"
    echo
    echo "### medir.sh"
    bash "$RAIZ/medir.sh" "$BIN/branch" "$REP"
} 2>&1 | tee "$SAIDA/parte2_branch.txt"
