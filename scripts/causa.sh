#!/usr/bin/env bash
set -u
. "$(dirname "$0")/comum.sh"

PROG=$1
ROTULO=$2
VG=${VALGRIND:-valgrind}

echo "## $ROTULO ($PROG)"

if command -v perf >/dev/null 2>&1; then
    for modo in aleatorio sort; do
        echo "-- perf stat: $modo $REP"
        perf stat -e branches,branch-misses "$PROG" "$modo" "$REP" 2>&1 | grep -E 'modo=|branches|branch-misses|elapsed' || true
    done
else
    echo "-- perf: nao instalado"
fi

if command -v "$VG" >/dev/null 2>&1; then
    for reps in "$REP_VG" $((REP_VG * 5)); do
        for modo in aleatorio sort; do
            echo "-- valgrind cachegrind: $modo $reps"
            "$VG" --tool=cachegrind --cache-sim=no --branch-sim=yes --cachegrind-out-file=/dev/null "$PROG" "$modo" "$reps" 2>&1 | grep -E 'modo=|Branches|Mispredicts|Mispred rate' || true
        done
    done
else
    echo "-- valgrind: nao instalado"
fi
