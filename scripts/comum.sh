RAIZ=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BIN=${BIN:-/tmp/maonamassa}
SAIDA="$RAIZ/resultados"
REP=${REP:-10000}
REPS_VG=${REPS_VG:-"20 100 500"}
mkdir -p "$BIN" "$SAIDA/asm"

mediana() {
    sort -n | awk '{ a[NR] = $1 } END { print (NR % 2) ? a[(NR + 1) / 2] : (a[NR / 2] + a[NR / 2 + 1]) / 2 }'
}
