#!/usr/bin/env bash
# Roda ./branch 5 vezes em cada modo, mostra a mediana dos tempos e,
# se o perf estiver disponível (Linux), mede branches e branch-misses.
#
# Uso:  ./medir.sh [executável] [repetições]
#       ./medir.sh                      # usa ./branch e 10000 repetições
#       ./medir.sh ./branchless 10000

set -e

PROG=${1:-./branch}
REP=${2:-10000}
EXECUCOES=5

if [ ! -x "$PROG" ]; then
    echo "Executável $PROG não encontrado. Rode 'make' antes." >&2
    exit 1
fi

mediana() {
    # lê números (um por linha) e imprime a mediana
    sort -n | awk '{ a[NR] = $1 } END { print (NR % 2) ? a[(NR + 1) / 2] : (a[NR / 2] + a[NR / 2 + 1]) / 2 }'
}

for modo in aleatorio sort; do
    echo "== $PROG $modo ($EXECUCOES execuções) =="
    tempos=""
    for i in $(seq 1 $EXECUCOES); do
        linha=$("$PROG" "$modo" "$REP")
        echo "   $linha"
        t=$(echo "$linha" | sed -E 's/.*tempo=([0-9.]+).*/\1/')
        tempos="$tempos$t"$'\n'
    done
    echo "   mediana: $(printf '%s' "$tempos" | mediana) s"
    echo
done

if command -v perf >/dev/null 2>&1; then
    for modo in aleatorio sort; do
        echo "== perf stat: $PROG $modo =="
        perf stat -e branches,branch-misses "$PROG" "$modo" "$REP" 2>&1 | grep -E 'branch|elapsed' || true
        echo
    done
else
    echo "perf não encontrado (ele só existe no Linux)."
    echo "Alternativa: valgrind --tool=cachegrind --cache-sim=no --branch-sim=yes $PROG aleatorio 20"
fi
