#!/usr/bin/env bash
set -u
. "$(dirname "$0")/comum.sh"

{
    echo "data: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "kernel: $(uname -srmo)"
    echo "so: $(. /etc/os-release && echo "$PRETTY_NAME")"
    echo "gcc: $(gcc --version | head -1)"
    echo "make: $(make --version | head -1)"
    if command -v perf >/dev/null 2>&1; then
        echo "perf: $(perf --version 2>&1 | head -1)"
    else
        echo "perf: nao instalado (contadores lidos com scripts/contadores.c, via perf_event_open)"
    fi
    if command -v valgrind >/dev/null 2>&1; then
        echo "valgrind: $(valgrind --version)"
    else
        echo "valgrind: nao instalado"
    fi
    echo "repeticoes: $REP"
    echo
    lscpu | grep -E "Model name|MHz|^CPU\(s\)|Thread|Core|Socket|Hypervisor|L1d|L2|L3|Architecture|Vendor"
} 2>&1 | tee "$SAIDA/00_ambiente.txt"
