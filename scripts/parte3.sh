#!/usr/bin/env bash
set -eu
. "$(dirname "$0")/comum.sh"
bash "$(dirname "$0")/compilar.sh" >/dev/null

bash "$(dirname "$0")/causa.sh" "$BIN/branch" branch 2>&1 | tee "$SAIDA/parte3_branch_causa.txt"
bash "$(dirname "$0")/causa.sh" "$BIN/branchless" branchless 2>&1 | tee "$SAIDA/parte4_branchless_causa.txt"
bash "$(dirname "$0")/causa.sh" "$BIN/branch_esperto" branch_esperto 2>&1 | tee "$SAIDA/parte4_esperto_causa.txt"
bash "$(dirname "$0")/causa.sh" "$BIN/branch250" branch250 2>&1 | tee "$SAIDA/parte5_branch250_causa.txt"
