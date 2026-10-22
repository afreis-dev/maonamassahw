#!/usr/bin/env bash
set -eu
. "$(dirname "$0")/comum.sh"
bash "$(dirname "$0")/compilar.sh" >/dev/null

{
    echo "### execucao unica de cada modo"
    "$BIN/branch250" aleatorio "$REP"
    "$BIN/branch250" sort "$REP"
    echo
    echo "### medir.sh"
    bash "$RAIZ/medir.sh" "$BIN/branch250" "$REP"
} 2>&1 | tee "$SAIDA/parte5_branch250.txt"

CSV="$SAIDA/parte5_curva_limiar.csv"
echo "limiar,modo,mediana_s,t1,t2,t3,t4,t5,soma" > "$CSV"
for L in 0 32 64 96 128 160 192 224 250 256; do
    gcc -O1 -DLIMIAR="$L" -o "$BIN/b" "$RAIZ/branch.c"
    for modo in aleatorio sort; do
        tempos=()
        soma=0
        for i in 1 2 3 4 5; do
            linha=$("$BIN/b" "$modo" "$REP")
            tempos+=("$(echo "$linha" | sed -E 's/.*tempo=([0-9.]+).*/\1/')")
            soma=$(echo "$linha" | sed -E 's/.*soma=([0-9]+).*/\1/')
        done
        med=$(printf '%s\n' "${tempos[@]}" | mediana)
        echo "$L,$modo,$med,$(IFS=,; echo "${tempos[*]}"),$soma" >> "$CSV"
        echo "limiar=$L modo=$modo mediana=$med"
    done
done
