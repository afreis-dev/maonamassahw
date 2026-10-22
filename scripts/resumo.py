import csv
import json
import re
import statistics
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
RES = RAIZ / "resultados"
REP = 10000
N = 32768
ITERACOES = REP * N
SOMA_ESPERADA_RIPES = 733


def br(valor, casas=3):
    if valor is None:
        return "n/d"
    texto = f"{valor:,.{casas}f}"
    return texto.replace(",", "#").replace(".", ",").replace("#", ".")


def inteiro(valor):
    return br(valor, 0)


def ler(nome):
    caminho = RES / nome
    return caminho.read_text(encoding="utf-8") if caminho.exists() else ""


def numero(texto):
    return int(re.sub(r"[.,\s]", "", texto))


def parse_medir(texto):
    resultado = {}
    atual = None
    for linha in texto.splitlines():
        m = re.match(r"== (\S+) (aleatorio|sort) \(", linha)
        if m:
            atual = (Path(m.group(1)).name, m.group(2))
            resultado[atual] = {"tempos": [], "soma": None, "mediana": None}
            continue
        if atual is None:
            continue
        m = re.match(r"\s{3}modo=.*soma=(\d+) tempo=([\d.]+) s", linha)
        if m:
            resultado[atual]["soma"] = int(m.group(1))
            resultado[atual]["tempos"].append(float(m.group(2)))
            continue
        m = re.match(r"\s+mediana: ([\d.]+) s", linha)
        if m:
            resultado[atual]["mediana"] = float(m.group(1))
    return resultado


def parse_causa(texto):
    hw = {"aleatorio": [], "sort": []}
    vg = {}
    atual = None
    for linha in texto.splitlines():
        m = re.match(r"-- (?:contadores \(perf_event_open\)|perf stat): (aleatorio|sort) \d+", linha)
        if m:
            atual = ("hw", m.group(1))
            hw[m.group(1)].append({"branches": None, "misses": None})
            continue
        m = re.match(r"-- valgrind cachegrind: (aleatorio|sort) (\d+)", linha)
        if m:
            atual = ("vg", m.group(1), int(m.group(2)))
            vg[(m.group(1), int(m.group(2)))] = {}
            continue
        if atual is None:
            continue
        if atual[0] == "hw":
            m = re.match(r"\s*([\d.,]+)\s+branches\b", linha)
            if m:
                hw[atual[1]][-1]["branches"] = numero(m.group(1))
            m = re.match(r"\s*([\d.,]+)\s+branch-misses\b", linha)
            if m:
                hw[atual[1]][-1]["misses"] = numero(m.group(1))
        else:
            chave = (atual[1], atual[2])
            m = re.search(r"Branches:\s+([\d,]+)\s+\(\s*([\d,]+) cond", linha)
            if m:
                vg[chave]["branches"] = numero(m.group(1))
                vg[chave]["cond_branches"] = numero(m.group(2))
            m = re.search(r"Mispredicts:\s+([\d,]+)\s+\(\s*([\d,]+) cond", linha)
            if m:
                vg[chave]["misses"] = numero(m.group(1))
                vg[chave]["cond_misses"] = numero(m.group(2))
    return hw, vg


def mediana_hw(lista, campo):
    valores = [x[campo] for x in lista if x[campo] is not None]
    return statistics.median(valores) if valores else None


def diferencial_vg(vg, modo):
    reps = sorted(r for (m, r) in vg if m == modo)
    if len(reps) < 2:
        return None
    r1, r2 = reps[-2], reps[-1]
    a, b = vg[(modo, r1)], vg[(modo, r2)]
    dr = r2 - r1
    por_rep = {k: (b[k] - a[k]) / dr for k in ("branches", "cond_branches", "misses", "cond_misses")}
    inicio = {k: a[k] - por_rep[k] * r1 for k in por_rep}
    return {"r1": r1, "r2": r2, "por_rep": por_rep, "inicio": inicio}


def pct(parte, total):
    return 100.0 * parte / total if total else 0.0


def frequencia_cperf():
    valores = [float(x) for x in re.findall(r"FREQUENCIA EFETIVA\s*:\s*([\d.]+) GHz", ler("00_frequencia_cperf.txt"))]
    return statistics.median(valores) if valores else None


def linha_tabela(celulas):
    return "| " + " | ".join(str(c) for c in celulas) + " |"


def tabela(cabecalho, linhas):
    saida = [linha_tabela(cabecalho), linha_tabela(["---"] * len(cabecalho))]
    saida += [linha_tabela(l) for l in linhas]
    return "\n".join(saida)


def tempos_txt(tempos):
    return " / ".join(br(t, 3) for t in tempos)


def carregar():
    d = {}
    d["medir"] = {}
    for arquivo in ("parte2_branch.txt", "parte4_branchless.txt", "parte4_esperto.txt", "parte5_branch250.txt"):
        d["medir"].update(parse_medir(ler(arquivo)))
    d["causa"] = {}
    for rotulo, arquivo in (
        ("branch", "parte3_branch_causa.txt"),
        ("branchless", "parte4_branchless_causa.txt"),
        ("branch_esperto", "parte4_esperto_causa.txt"),
        ("branch250", "parte5_branch250_causa.txt"),
    ):
        d["causa"][rotulo] = parse_causa(ler(arquivo))
        hw, _ = d["causa"][rotulo]
        if mediana_hw(hw["aleatorio"], "misses") is None or mediana_hw(hw["sort"], "misses") is None:
            raise SystemExit(
                f"sem contadores de hardware em resultados/{arquivo}: "
                "rode scripts/parte3.sh em uma máquina onde o perf (ou scripts/contadores.c) consiga ler branches e branch-misses"
            )
    return d


def secao_ambiente(f):
    ambiente = ler("00_ambiente.txt")
    cpu = re.search(r"Model name:\s+(.+)", ambiente)
    so = re.search(r"^so: (.+)$", ambiente, re.M)
    kernel = re.search(r"^kernel: (.+)$", ambiente, re.M)
    gcc = re.search(r"^gcc: (.+)$", ambiente, re.M)
    vg = re.search(r"^valgrind: (.+)$", ambiente, re.M)
    freq = frequencia_cperf()
    nominal = re.search(r"@\s*([\d.]+)\s*GHz", cpu.group(1)) if cpu else None
    nominal_br = br(float(nominal.group(1)), 2) if nominal else "?"
    linhas = [
        ["CPU (modelo)", cpu.group(1).strip() if cpu else "?"],
        ["Frequência (GHz)", f"{nominal_br} nominal (lscpu); {br(freq, 2)} efetiva sob carga (cperf)" if freq else f"{nominal_br} nominal (lscpu)"],
        ["Sistema operacional", f"{so.group(1) if so else '?'} em WSL2 (kernel {kernel.group(1).split()[1] if kernel else '?'}), host Windows 11"],
        ["Compilador e versão", gcc.group(1) if gcc else "?"],
        ["Ferramenta de medição", f"contadores de hardware via perf_event_open (scripts/contadores.c, mesmos eventos do perf stat) e {vg.group(1) if vg else 'Valgrind'} (cachegrind --branch-sim)"],
        ["Nº de repetições", inteiro(REP)],
    ]
    f.write("## Ambiente\n\n" + tabela(["Item", "Valor"], linhas) + "\n\n")


def secao_tabela1(f, d):
    medir = d["medir"]
    hw, vg = d["causa"]["branch"]
    linhas = []
    for nome, modo, chave in (("Aleatório", "aleatorio", ("branch", "aleatorio")), ("Ordenado", "sort", ("branch", "sort"))):
        m = medir[chave]
        b = mediana_hw(hw[modo], "branches")
        e = mediana_hw(hw[modo], "misses")
        linhas.append([nome, tempos_txt(m["tempos"]), br(m["mediana"], 3), inteiro(b), inteiro(e), br(pct(e, b), 2) + "%"])
    f.write("## Partes 2 e 3 — Tabela 1 (branch, LIMIAR = 128)\n\n")
    f.write(tabela(["Versão", "Tempo — 5 execuções (s)", "Mediana (s)", "branches", "branch-misses", "% de erro"], linhas) + "\n\n")
    ta = medir[("branch", "aleatorio")]["mediana"]
    to = medir[("branch", "sort")]["mediana"]
    f.write(f"Razão tempo_aleatório / tempo_ordenado = **{br(ta / to, 2)} ×** ({br(ta, 3)} s / {br(to, 3)} s)\n\n")
    somas = {medir[("branch", "aleatorio")]["soma"], medir[("branch", "sort")]["soma"]}
    f.write(f"Soma nos dois modos: {', '.join(inteiro(s) for s in somas)} ({'idêntica' if len(somas) == 1 else 'DIFERENTE'}).\n\n")

    ba = mediana_hw(hw["aleatorio"], "branches")
    bo = mediana_hw(hw["sort"], "branches")
    f.write("### 3.3.2 — conta de conferência\n\n")
    f.write(f"- branches (aleatório) ÷ (repetições × 32.768) = {inteiro(ba)} ÷ {inteiro(ITERACOES)} = **{br(ba / ITERACOES, 3)} desvios por iteração**\n")
    f.write(f"- branches (ordenado) ÷ (repetições × 32.768) = {br(bo / ITERACOES, 3)} (o `qsort` antes do laço soma desvios ao total)\n")
    dif = vg and diferencial_vg(vg, "aleatorio")
    if dif:
        f.write(
            f"- Valgrind, só o laço (diferença entre {dif['r1']} e {dif['r2']} repetições): "
            f"{br(dif['por_rep']['cond_branches'] / N, 3)} desvios **condicionais** por iteração\n"
        )
    f.write("- Interpretação: o `if` e a condição do `for` são 2 desvios condicionais por iteração; o `jmp` que fecha o bloco do `if` quando ele é executado soma ≈ 0,5 desvio incondicional por iteração (o `perf` conta todos os desvios). Só o `if` erra, e erra em ≈ metade das vezes.\n\n")

    f.write("### 3.3.3 — custo estimado de cada erro de previsão\n\n")
    ea = mediana_hw(hw["aleatorio"], "misses")
    eo = mediana_hw(hw["sort"], "misses")
    extras = ea - eo
    tempo_extra = ta - to
    freq = frequencia_cperf()
    linhas = [["erros_extras = misses_aleatório − misses_ordenado", f"{inteiro(ea)} − {inteiro(eo)} = {inteiro(extras)}"],
              ["tempo_extra = tempo_aleatório − tempo_ordenado", f"{br(ta, 3)} − {br(to, 3)} = {br(tempo_extra, 3)} s"]]
    if freq:
        linhas.append(["frequência efetiva (cperf)", f"{br(freq, 3)} GHz"])
        linhas.append(["custo_por_erro (ciclos), frequência efetiva", f"{br(tempo_extra * freq * 1e9 / extras, 1)} ciclos"])
    linhas.append(["custo_por_erro (ciclos), frequência nominal 2,90 GHz", f"{br(tempo_extra * 2.9e9 / extras, 1)} ciclos"])
    f.write(tabela(["Passo", "Valor"], linhas) + "\n\n")
    calibrada = re.search(r"Use ([\d.]+) GHz como refer", ler("00_frequencia_cperf.txt"))
    if freq and calibrada:
        ref = float(calibrada.group(1))
        f.write(
            f"Observação: o `cperf calib` indica {br(ref, 3)} GHz como referência (uma única medição); com esse valor o custo seria "
            f"{br(tempo_extra * ref * 1e9 / extras, 1)} ciclos. Usamos a mediana das 3 medições de `cperf freq` ({br(freq, 3)} GHz).\n\n"
        )
    if freq:
        f.write(f"Ciclos por iteração do laço: aleatório {br(ta * freq * 1e9 / ITERACOES, 2)}, ordenado {br(to * freq * 1e9 / ITERACOES, 2)} (a {br(freq, 1)} GHz efetivos).\n\n")

    f.write("### Valgrind (cachegrind --branch-sim=yes), simulador de preditor\n\n")
    linhas = []
    for modo, nome in (("aleatorio", "Aleatório"), ("sort", "Ordenado")):
        for (m, reps), v in sorted(vg.items(), key=lambda kv: kv[0][1]):
            if m != modo:
                continue
            linhas.append([nome, reps, inteiro(v["branches"]), inteiro(v["misses"]), br(pct(v["misses"], v["branches"]), 1) + "%"])
    f.write(tabela(["Versão", "Repetições", "Branches", "Mispredicts", "Taxa"], linhas) + "\n\n")
    linhas = []
    for modo, nome in (("aleatorio", "Aleatório"), ("sort", "Ordenado")):
        dif = diferencial_vg(vg, modo)
        if dif:
            p = dif["por_rep"]
            linhas.append([nome, br(p["cond_branches"] / N, 3), br(p["cond_misses"] / N, 4), br(pct(p["cond_misses"], p["cond_branches"]), 2) + "%"])
    f.write("Só o laço (diferença entre as duas maiores contagens de repetições; remove o custo fixo de `rand` e `qsort`):\n\n")
    f.write(tabela(["Versão", "desvios condicionais por iteração", "erros por iteração", "taxa de erro do laço"], linhas) + "\n\n")


def linha_modo(d, binario, modo, nome):
    m = d["medir"][(binario, modo)]
    hw, _ = d["causa"][binario]
    b = mediana_hw(hw[modo], "branches")
    e = mediana_hw(hw[modo], "misses")
    return m, b, e


def secao_tabela2(f, d):
    mesa = ler("parte4_teste_de_mesa.txt")
    f.write("## Parte 4 — branchless\n\n### Teste de mesa da máscara\n\n```\n" + mesa.strip() + "\n```\n\n")
    soma_ref = d["medir"][("branch", "aleatorio")]["soma"]
    linhas = []
    for binario, modo, nome in (
        ("branch", "aleatorio", "branch - aleatório"),
        ("branch", "sort", "branch - ordenado"),
        ("branchless", "aleatorio", "branchless - aleatório"),
        ("branchless", "sort", "branchless - ordenado"),
    ):
        m, b, e = linha_modo(d, binario, modo, nome)
        linhas.append([nome, br(m["mediana"], 3), inteiro(e), br(pct(e, b), 2) + "%", "sim" if m["soma"] == soma_ref else "NÃO"])
    f.write("### Tabela 2\n\n" + tabela(["Versão", "Mediana (s)", "branch-misses", "% de erro", "soma confere?"], linhas) + "\n\n")
    linhas = []
    for binario, modo, nome in (("branchless", "aleatorio", "branchless - aleatório"), ("branchless", "sort", "branchless - ordenado")):
        m = d["medir"][(binario, modo)]
        linhas.append([nome, tempos_txt(m["tempos"]), br(m["mediana"], 3)])
    f.write("Tempos das 5 execuções do branchless:\n\n" + tabela(["Versão", "Tempos (s)", "Mediana (s)"], linhas) + "\n\n")

    f.write("### 4.5 — o compilador esperto\n\n")
    linhas = []
    for binario, rotulo in (("branch_esperto", "branch_esperto (-O1 -DSEM_BARREIRA)"), ("branch_esperto_O2", "branch_esperto (-O2 -DSEM_BARREIRA)")):
        a = d["medir"][(binario, "aleatorio")]
        o = d["medir"][(binario, "sort")]
        linhas.append([rotulo, br(a["mediana"], 3), br(o["mediana"], 3), "sim" if a["soma"] == soma_ref and o["soma"] == soma_ref else "NÃO"])
    f.write(tabela(["Binário", "aleatório (s)", "ordenado (s)", "soma confere?"], linhas) + "\n\n")
    hw, _ = d["causa"]["branch_esperto"]
    f.write(
        f"branch-misses do branch_esperto -O1: aleatório {inteiro(mediana_hw(hw['aleatorio'], 'misses'))}, "
        f"ordenado {inteiro(mediana_hw(hw['sort'], 'misses'))}.\n\n"
    )
    f.write("Trechos do laço interno (`resultados/parte4_trechos_asm.txt`):\n\n```\n" + ler("parte4_trechos_asm.txt").strip() + "\n```\n\n")


def secao_tabela3(f, d):
    linhas = []
    for binario, limiar in (("branch", 128), ("branch250", 250)):
        for modo, nome in (("aleatorio", "Aleatório"), ("sort", "Ordenado")):
            m, b, e = linha_modo(d, binario, modo, nome)
            linhas.append([limiar, nome, br(m["mediana"], 3), inteiro(e), br(pct(e, b), 2) + "%"])
    f.write("## Parte 5 — limiar 250\n\n### Tabela 3\n\n" + tabela(["Limiar", "Versão", "Mediana (s)", "branch-misses", "% de erro"], linhas) + "\n\n")
    ra = d["medir"][("branch", "aleatorio")]["mediana"] / d["medir"][("branch", "sort")]["mediana"]
    rb = d["medir"][("branch250", "aleatorio")]["mediana"] / d["medir"][("branch250", "sort")]["mediana"]
    f.write(f"Razão aleatório / ordenado: LIMIAR 128 = {br(ra, 2)} ×; LIMIAR 250 = {br(rb, 2)} ×.\n\n")

    linhas = []
    por_limiar = {}
    with (RES / "parte5_curva_limiar.csv").open(newline="", encoding="utf-8") as arquivo:
        for linha in csv.DictReader(arquivo):
            por_limiar.setdefault(int(linha["limiar"]), {})[linha["modo"]] = linha
    for limiar in sorted(por_limiar):
        a = por_limiar[limiar].get("aleatorio")
        o = por_limiar[limiar].get("sort")
        linhas.append([limiar, br(float(a["mediana_s"]), 3) if a else "", br(float(o["mediana_s"]), 3) if o else "", f"{(256 - limiar) / 256:.1%}".replace(".", ",")])
    f.write("### 5.4 — curva do limiar (mediana de 5 execuções)\n\n")
    f.write(tabela(["LIMIAR", "aleatório (s)", "ordenado (s)", "P(if verdadeiro) teórica"], linhas) + "\n\n")
    f.write(
        "A curva vem do `scripts/parte5.sh` (5 execuções por ponto, medidas à parte), por isso os pontos de LIMIAR 128 e 250 diferem um pouco das Tabelas 1 e 3, "
        "que vêm do `medir.sh`. A coluna de probabilidade é a teórica, (256 − LIMIAR) / 256, com valores uniformes de 0 a 255; no array sorteado "
        "a fração real de `v[i] >= LIMIAR` difere em até ~0,1 ponto percentual.\n\n"
    )
    f.write("Gráfico: `resultados/parte5_grafico_limiar.png`\n\n")


def ler_ripes(nome):
    caminho = RES / "ripes" / f"{nome}.json"
    if not caminho.exists():
        return None
    return json.loads(caminho.read_text(encoding="utf-8"))


def x13_texto(j):
    x13 = j["registers"]["x13"]
    return f"{inteiro(x13)} ({'correto' if x13 == SOMA_ESPERADA_RIPES else 'ERRADO'})"


def linha_ripes(rotulo, nome):
    j = ler_ripes(nome)
    if j is None:
        if (RES / "ripes" / f"{nome}.nao_termina.txt").exists():
            return [rotulo, "—", "—", "—", "não terminou (o Ripes ficou rodando além de 15 s)"]
        return [rotulo, "—", "—", "—", "sem dados"]
    return [rotulo, j["cycles"], j["# instructions retired"], br(j["CPI"], 3), x13_texto(j)]


def secao_ripes(f):
    f.write("## Parte 6 — Ripes\n\n")
    f.write(f"Soma esperada (calculada à mão): 200 + 150 + 255 + 128 = **{SOMA_ESPERADA_RIPES}**\n\n")
    f.write("### Tabela do relatório\n\n")
    linhas = [
        linha_ripes("5-stage processor", "5s_aleatorio"),
        linha_ripes("5-stage processor w/o forwarding unit", "5s_sem_fw_aleatorio"),
        linha_ripes("5-stage processor w/o forwarding or hazard detection (laco.s original)", "5s_sem_fw_hz_aleatorio"),
        linha_ripes("5-stage processor w/o forwarding or hazard detection (laco_sem_hz.s, 4 nops antes do ecall)", "5s_sem_fw_hz_aleatorio_com_nops"),
        linha_ripes("5-stage processor - dados ordenados", "5s_ordenado"),
    ]
    f.write(tabela(["Processador", "Cycles", "Instrs. retired", "CPI", "x13"], linhas) + "\n\n")
    base = ler_ripes("5s_aleatorio")
    semfw = ler_ripes("5s_sem_fw_aleatorio")
    if base and semfw:
        f.write(f"Forwarding economizou {semfw['cycles'] - base['cycles']} ciclos ({semfw['cycles']} → {base['cycles']}), CPI {br(semfw['CPI'], 3)} → {br(base['CPI'], 3)}.\n\n")
    ordenado = ler_ripes("5s_ordenado")
    if base and ordenado:
        f.write(f"Dados ordenados no processador completo: {ordenado['cycles']} ciclos contra {base['cycles']} com os dados originais. ")
        f.write("A ordem dos dados não muda nada: o número de desvios tomados é o mesmo (4 do `blt x5` + 7 do `blt x12`), então o Ripes usa previsão estática (sempre \"não desvia\"), sem histórico.\n\n")

    f.write("### Todas as execuções do Ripes\n\n")
    linhas = []
    for nome, processador, com_nops in (
        ("5s", "RV32_5S", False),
        ("5s_sem_fw", "RV32_5S_NO_FW", False),
        ("5s_sem_hz", "RV32_5S_NO_HZ", True),
        ("5s_sem_fw_hz", "RV32_5S_NO_FW_HZ", True),
    ):
        for dados, rotulo_dados in (("aleatorio", "originais"), ("ordenado", "ordenados")):
            linhas.append(linha_ripes(f"{processador}, dados {rotulo_dados}", f"{nome}_{dados}"))
            if com_nops:
                linhas.append(linha_ripes(f"{processador}, dados {rotulo_dados}, 4 nops antes do ecall", f"{nome}_{dados}_com_nops"))
    f.write(tabela(["Execução", "Cycles", "Instrs. retired", "CPI", "x13"], linhas) + "\n\n")

    f.write(
        "Sem hazard detection o `ecall` não é segurado e lê o `a7` do banco de registradores antes de o `addi x17, x0, 10` anterior chegar ao WB; "
        "por isso o `laco.s` original não termina nesses processadores (\"não terminou\" = o Ripes passou de 15 s). "
        "Medido: com 0, 1 ou 2 `nop` entre o `li a7, 10` e o `ecall` ainda não termina; com 3 ou mais termina (usamos 4 por margem, em `laco_sem_hz.s`). "
        "Cycles e Instrs. retired dessas linhas incluem os nops e o caminho errado que o laço percorre. "
        "Os processadores sem hazard detection executam o laço com valores velhos dos registradores (dependências RAW não resolvidas), por isso o x13 sai errado.\n\n"
    )
    f.write(
        "A tabela de pipeline exportada pelo Ripes para o processador sem forwarding vem truncada em 100 ciclos (a execução tem 114); "
        "Cycles, Instrs. retired e registradores estão completos.\n\n"
    )
    legendas = RES / "ripes" / "prints" / "legendas.txt"
    if legendas.exists():
        f.write("### Prints do pipeline (gerados a partir do relatório do Ripes, processador RV32_5S)\n\n")
        f.write("Arquivos em `resultados/ripes/prints/`. Legendas:\n\n```\n" + legendas.read_text(encoding="utf-8-sig").strip() + "\n```\n\n")

def main():
    d = carregar()
    with (RES / "DADOS_PARA_RELATORIO.md").open("w", encoding="utf-8", newline="\n") as f:
        f.write("# Dados para o relatório\n\nGerado por `scripts/resumo.py` a partir dos arquivos brutos em `resultados/`.\n\n")
        secao_ambiente(f)
        secao_tabela1(f, d)
        secao_tabela2(f, d)
        secao_tabela3(f, d)
        secao_ripes(f)
    print(RES / "DADOS_PARA_RELATORIO.md")


main()
