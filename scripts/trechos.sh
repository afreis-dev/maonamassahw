#!/usr/bin/env bash
set -eu
. "$(dirname "$0")/comum.sh"

trecho() {
    local arquivo=$1 padrao=$2 antes=$3 depois=$4
    echo "=== $arquivo"
    awk -v antes="$antes" -v depois="$depois" -v padrao="$padrao" '
        { l[NR] = $0 }
        $0 ~ padrao && !achou { achou = NR }
        END { for (i = achou - antes; i <= achou + depois; i++) print l[i] }
    ' "$SAIDA/asm/$arquivo"
    echo
}

trecho com_barreira.s 'cmpl[ \t]+[$]127' 5 6
trecho esperto.s 'cmpl[ \t]+[$]128' 5 6
trecho esperto_O2.s 'pcmpgtd' 7 14
trecho branchless.s 'cmpl[ \t]+[$]127' 5 6
