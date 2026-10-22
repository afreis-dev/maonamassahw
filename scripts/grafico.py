import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

raiz = Path(__file__).resolve().parent.parent
entrada = raiz / "resultados" / "parte5_curva_limiar.csv"
saida = raiz / "resultados" / "parte5_grafico_limiar.png"

series = {}
with entrada.open(newline="") as f:
    for linha in csv.DictReader(f):
        series.setdefault(linha["modo"], []).append((int(linha["limiar"]), float(linha["mediana_s"])))

fig, ax = plt.subplots(figsize=(8, 4.5))
for modo, rotulo in (("aleatorio", "Array aleatório"), ("sort", "Array ordenado")):
    pontos = sorted(series.get(modo, []))
    if not pontos:
        continue
    ax.plot([p[0] for p in pontos], [p[1] for p in pontos], marker="o", label=rotulo)
    if modo == "aleatorio":
        for x, y in pontos:
            ax.annotate(f"{y:.2f}", (x, y), textcoords="offset points", xytext=(0, 7), ha="center", fontsize=7)

ax.set_xlabel("LIMIAR")
ax.set_ylabel("Tempo (s) — mediana de 5 execuções")
ax.set_title("Tempo × LIMIAR (branch.c, -O1, 10000 repetições)")
ax.set_xticks([0, 32, 64, 96, 128, 160, 192, 224, 250, 256])
ax.grid(True, alpha=0.3)
ax.legend()
fig.tight_layout()
fig.savefig(saida, dpi=150)
print(saida)
