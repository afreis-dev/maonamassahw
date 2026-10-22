# Mão na massa: o custo de errar a previsão de desvio

Infraestrutura de Hardware — CESAR School

## Integrantes

- Arthur Filipe Silva dos Reis
- Matheus Assis da Souza Jácome

## Conteúdo

| Caminho | Descrição |
|---|---|
| `branch.c`, `Makefile`, `medir.sh` | Material da aula, sem alterações |
| `branchless.c` | Versão sem desvio: o `if` vira máscara aritmética (Parte 4) |
| `ripes/laco.s` | Laço em Assembly RISC-V completo (Parte 6) |
| `ripes/laco_ordenado.s` | Mesmo laço com os dados ordenados (Passo 6.7.3) |
| `ripes/laco_sem_hz*.s` | Mesmo laço com 4 `nop` antes do `ecall`: sem hazard detection o `ecall` lê o `a7` antigo e o programa original não termina (são necessários pelo menos 3 `nop`) |
| `scripts/` | Scripts que geram as medições (a frequência real vem do `cperf` do laboratório anterior, ver abaixo) |
| `resultados/` | Saídas brutas, Assembly gerado, gráfico e diagramas do pipeline |
| `resultados/DADOS_PARA_RELATORIO.md` | Tabelas 1 a 3, contas e dados do Ripes prontos para o relatório |

## Como reproduzir

Linux ou WSL2 (Ubuntu), com `gcc` e `make`:

```bash
sudo apt install build-essential linux-tools-common linux-tools-generic valgrind
bash scripts/rodar_tudo.sh
python3 scripts/resumo.py
```

Se o `perf` não estiver instalado ou não conseguir ler os contadores (comum no WSL2), `scripts/contadores.c` lê `branches` e `branch-misses` pela mesma chamada de sistema (`perf_event_open`) e imprime no formato do `perf stat`. Os scripts usam o `perf` quando ele funciona.

`resultados/00_frequencia_cperf.txt` (frequência efetiva de 4,0 GHz, usada no custo por erro de previsão) foi gerado pelo `cperf freq` e `cperf calib` do laboratório "Medindo a CPU", compilado com `gcc -O2 -fno-unroll-loops`; nenhum script deste repositório o executa.

Parte 6 (Windows, com o Ripes v2.2.6 baixado de https://github.com/mortbopet/Ripes/releases):

```powershell
.\scripts\ripes.ps1 -Ripes C:\caminho\para\Ripes.exe
.\scripts\ripes_diagramas.ps1
.\scripts\grafico.ps1
python scripts\resumo.py
```

## Resultados principais

Intel Core i5-10400 (4,0 GHz efetivos sob carga), Ubuntu 26.04 em WSL2, gcc 15.2.0, `-O1`, 10000 repetições, mediana de 5 execuções.

| Versão | Aleatório | Ordenado |
|---|---|---|
| `branch`, LIMIAR 128 | 1,094 s (19,9% de erro) | 0,125 s (0,02% de erro) |
| `branchless`, LIMIAR 128 | 0,184 s | 0,182 s |
| `branch`, LIMIAR 250 | 0,155 s (1,3% de erro) | 0,086 s |

No Ripes, o `laco.s` termina com `x13 = 733` em 88 ciclos e 52 instruções no processador de 5 estágios completo.
