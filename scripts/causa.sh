#!/usr/bin/env bash
set -u
. "$(dirname "$0")/comum.sh"

PROG=$1
ROTULO=$2
VG=${VALGRIND:-valgrind}

echo "## $ROTULO ($PROG)"

CONTADOR=""
NOME_CONTADOR=""
if perf_funciona; then
    CONTADOR="perf stat -e branches,branch-misses"
    NOME_CONTADOR="perf stat"
elif [ -x "$BIN/contadores" ]; then
    CONTADOR="$BIN/contadores"
    NOME_CONTADOR="contadores (perf_event_open)"
fi

if [ -n "$CONTADOR" ]; then
    for modo in aleatorio sort; do
        for i in 1 2 3 4 5; do
            echo "-- $NOME_CONTADOR: $modo $REP (execucao $i)"
            $CONTADOR "$PROG" "$modo" "$REP" 2>&1 | grep -E 'modo=|branches|branch-misses|elapsed' || true
        done
    done
else
    echo "-- contadores de hardware: indisponiveis"
fi

if command -v "$VG" >/dev/null 2>&1; then
    for reps in $REPS_VG; do
        for modo in aleatorio sort; do
            echo "-- valgrind cachegrind: $modo $reps"
            "$VG" --tool=cachegrind --cache-sim=no --branch-sim=yes --cachegrind-out-file=/dev/null "$PROG" "$modo" "$reps" 2>&1 | grep -E 'modo=|Branches|Mispredicts|Mispred rate' || true
        done
    done
else
    echo "-- valgrind: nao instalado"
fi
