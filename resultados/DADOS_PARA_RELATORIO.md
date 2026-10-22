# Dados para o relatório

Gerado por `scripts/resumo.py` a partir dos arquivos brutos em `resultados/`.

## Ambiente

| Item | Valor |
| --- | --- |
| CPU (modelo) | Intel(R) Core(TM) i5-10400 CPU @ 2.90GHz |
| Frequência (GHz) | 2,90 nominal (lscpu); 4,01 efetiva sob carga (cperf) |
| Sistema operacional | Ubuntu 26.04 LTS em WSL2 (kernel 6.18.33.2-microsoft-standard-WSL2), host Windows 11 |
| Compilador e versão | gcc (Ubuntu 15.2.0-16ubuntu1) 15.2.0 |
| Ferramenta de medição | contadores de hardware via perf_event_open (scripts/contadores.c, mesmos eventos do perf stat) e valgrind-3.26.0 (cachegrind --branch-sim) |
| Nº de repetições | 10000 |

## Partes 2 e 3 — Tabela 1 (branch, LIMIAR = 128)

| Versão | Tempo — 5 execuções (s) | Mediana (s) | branches | branch-misses | % de erro |
| --- | --- | --- | --- | --- | --- |
| Aleatório | 1,105 / 1,094 / 1,094 / 1,098 / 1,093 | 1,094 | 820.529.652 | 163.157.161 | 19,88% |
| Ordenado | 0,125 / 0,125 / 0,125 / 0,124 / 0,124 | 0,125 | 823.222.922 | 199.734 | 0,02% |

Razão tempo_aleatório / tempo_ordenado = **8,75 ×** (1,094 s / 0,125 s)

Soma nos dois modos: 31.493.160.000 (idêntica).

### 3.3.2 — conta de conferência

- branches (aleatório) ÷ (repetições × 32.768) = 820.529.652 ÷ 327.680.000 = **2,504 desvios por iteração**
- branches (ordenado) ÷ (repetições × 32.768) = 2,512 (o `qsort` antes do laço soma desvios ao total)
- Valgrind, só o laço (diferença entre 100 e 500 repetições): 2,000 desvios **condicionais** por iteração
- Interpretação: o `if` e a condição do `for` são 2 desvios condicionais por iteração; o `jmp` que fecha o bloco do `if` quando ele é executado soma ≈ 0,5 desvio incondicional por iteração (o `perf` conta todos os desvios). Só o `if` erra, e erra em ≈ metade das vezes.

### 3.3.3 — custo estimado de cada erro de previsão

| Passo | Valor |
| --- | --- |
| erros_extras = misses_aleatório − misses_ordenado | 163.157.161 − 199.734 = 162.957.427 |
| tempo_extra = tempo_aleatório − tempo_ordenado | 1,094 − 0,125 = 0,969 s |
| frequência efetiva (cperf) | 4,009 GHz |
| custo_por_erro (ciclos), frequência efetiva | 23,8 ciclos |
| custo_por_erro (ciclos), frequência nominal 2,90 GHz | 17,2 ciclos |

Ciclos por iteração do laço: aleatório 13,38, ordenado 1,53 (a 4,0 GHz efetivos).

### Valgrind (cachegrind --branch-sim=yes), simulador de preditor

| Versão | Repetições | Branches | Mispredicts | Taxa |
| --- | --- | --- | --- | --- |
| Aleatório | 20 | 1.627.654 | 333.590 | 20,5% |
| Aleatório | 100 | 6.870.617 | 1.646.075 | 24,0% |
| Aleatório | 500 | 33.085.420 | 8.208.470 | 24,8% |
| Ordenado | 20 | 3.830.241 | 211.667 | 5,5% |
| Ordenado | 100 | 9.073.207 | 211.829 | 2,3% |
| Ordenado | 500 | 35.288.007 | 212.623 | 0,6% |

Só o laço (diferença entre as duas maiores contagens de repetições; remove o custo fixo de `rand` e `qsort`):

| Versão | desvios condicionais por iteração | erros por iteração | taxa de erro do laço |
| --- | --- | --- | --- |
| Aleatório | 2,000 | 0,5007 | 25,03% |
| Ordenado | 2,000 | 0,0001 | 0,00% |

## Parte 4 — branchless

### Teste de mesa da máscara

```
v[i]   v[i]>=128    mascara (dec)    mascara (bin, 32 bits)             v[i] & mascara
200    1            -1               11111111111111111111111111111111   200
50     0            0                00000000000000000000000000000000   0
```

### Tabela 2

| Versão | Mediana (s) | branch-misses | % de erro | soma confere? |
| --- | --- | --- | --- | --- |
| branch - aleatório | 1,094 | 163.157.161 | 19,88% | sim |
| branch - ordenado | 0,125 | 199.734 | 0,02% | sim |
| branchless - aleatório | 0,184 | 13.731 | 0,00% | sim |
| branchless - ordenado | 0,182 | 186.039 | 0,06% | sim |

Tempos das 5 execuções do branchless:

| Versão | Tempos (s) | Mediana (s) |
| --- | --- | --- |
| branchless - aleatório | 0,184 / 0,187 / 0,181 / 0,181 / 0,184 | 0,184 |
| branchless - ordenado | 0,182 / 0,181 / 0,180 / 0,183 / 0,183 | 0,182 |

### 4.5 — o compilador esperto

| Binário | aleatório (s) | ordenado (s) | soma confere? |
| --- | --- | --- | --- |
| branch_esperto (-O1 -DSEM_BARREIRA) | 0,190 | 0,199 | sim |
| branch_esperto (-O2 -DSEM_BARREIRA) | 0,110 | 0,106 | sim |

branch-misses do branch_esperto -O1: aleatório 13.706, ordenado 186.233.

Trechos do laço interno (`resultados/parte4_trechos_asm.txt`):

```
=== com_barreira.s
	addq	$4, %rax
	cmpq	%rbx, %rax
	je	.L26
.L11:
	movl	(%rax), %edx
	cmpl	$127, %edx
	jle	.L10
	movslq	%edx, %rdx
	addq	%rdx, %rbp
	jmp	.L10
.L26:
	addl	$1, %ecx

=== esperto.s
	.p2align 5
.L11:
	movl	(%rax), %ecx
	movslq	%ecx, %rdx
	addq	%rbx, %rdx
	cmpl	$128, %ecx
	cmovge	%rdx, %rbx
	addq	$4, %rax
	cmpq	%rbp, %rax
	jne	.L11
	addl	$1, %esi
	cmpl	%esi, %r12d

=== esperto_O2.s
.L12:
	movd	(%rax), %xmm7
	addq	$4, %rax
	pshufd	$0, %xmm7, %xmm0
	movdqa	%xmm0, %xmm1
	movdqa	%xmm0, %xmm3
	movdqa	%xmm0, %xmm2
	pcmpgtd	%xmm8, %xmm1
	psrad	$31, %xmm3
	punpckldq	%xmm3, %xmm2
	punpckhdq	%xmm3, %xmm0
	movdqa	%xmm1, %xmm4
	movdqa	%xmm1, %xmm7
	psrad	$31, %xmm4
	punpckldq	%xmm4, %xmm7
	punpckhdq	%xmm4, %xmm1
	pand	%xmm7, %xmm2
	pand	%xmm1, %xmm0
	paddq	%xmm2, %xmm5
	paddq	%xmm0, %xmm6
	cmpq	%r15, %rax
	jne	.L12

=== branchless.s
.L9:
	movq	%r13, %rdx
	.p2align 5
.L10:
	movl	(%rdx), %eax
	cmpl	$127, %eax
	cmovle	%ecx, %eax
	cltq
	addq	%rax, %rbx
	addq	$4, %rdx
	cmpq	%rbp, %rdx
	jne	.L10
```

## Parte 5 — limiar 250

### Tabela 3

| Limiar | Versão | Mediana (s) | branch-misses | % de erro |
| --- | --- | --- | --- | --- |
| 128 | Aleatório | 1,094 | 163.157.161 | 19,88% |
| 128 | Ordenado | 0,125 | 199.734 | 0,02% |
| 250 | Aleatório | 0,155 | 8.768.560 | 1,32% |
| 250 | Ordenado | 0,086 | 196.158 | 0,03% |

Razão aleatório / ordenado: LIMIAR 128 = 8,75 ×; LIMIAR 250 = 1,80 ×.

### 5.4 — curva do limiar (mediana de 5 execuções)

| LIMIAR | aleatório (s) | ordenado (s) | P(if verdadeiro) |
| --- | --- | --- | --- |
| 0 | 0,169 | 0,167 | 100,0% |
| 32 | 0,478 | 0,158 | 87,5% |
| 64 | 0,819 | 0,149 | 75,0% |
| 96 | 1,072 | 0,141 | 62,5% |
| 128 | 1,114 | 0,127 | 50,0% |
| 160 | 0,981 | 0,119 | 37,5% |
| 192 | 0,767 | 0,117 | 25,0% |
| 224 | 0,504 | 0,105 | 12,5% |
| 250 | 0,186 | 0,098 | 2,3% |
| 256 | 0,087 | 0,088 | 0,0% |

Gráfico: `resultados/parte5_grafico_limiar.png`

## Parte 6 — Ripes

Soma esperada (calculada à mão): 200 + 150 + 255 + 128 = **733**

| Processador | Cycles | Instrs. retired | CPI | x13 |
| --- | --- | --- | --- | --- |
| 5-stage processor | 88 | 52 | 1,692 | 733 (correto) |
| 5-stage processor w/o forwarding unit | 114 | 52 | 2,192 | 733 (correto) |
| 5-stage w/o forwarding or hazard detection (laco.s original) | — | — | — | NÃO TERMINA: o `li a7, 10` é seguido direto do `ecall`, que lê o a7 antigo; sem hazard detection a execução não acaba |
| 5-stage w/o forwarding or hazard detection (laco_sem_hz.s: 4 nops antes do ecall) | 86 | 66 | 1,303 | 426576476 (ERRADO) |
| 5-stage processor — dados ordenados | 88 | 52 | 1,692 | 733 (correto) |
| extra: 5-stage w/o hazard detection (laco.s original) | — | — | — | NÃO TERMINA: o `li a7, 10` é seguido direto do `ecall`, que lê o a7 antigo; sem hazard detection a execução não acaba |
| extra: 5-stage w/o hazard detection (laco_sem_hz.s) | 90 | 62 | 1,452 | 313 (ERRADO) |
| extra: 5-stage w/o forwarding unit — dados ordenados | 114 | 52 | 2,192 | 733 (correto) |
| extra: 5-stage w/o fw/hazard — dados ordenados (laco_sem_hz_ordenado.s) | 86 | 66 | 1,303 | 426576476 (ERRADO) |

Forwarding economizou 26 ciclos (114 → 88), CPI 2,192 → 1,692.

Dados ordenados no processador completo: 88 ciclos contra 88 com os dados originais. A ordem dos dados não muda nada: o número de desvios tomados é o mesmo (4 do `blt x5` + 7 do `blt x12`), então o Ripes usa previsão estática (sempre "não desvia"), sem histórico.

Os processadores sem hazard detection executam o programa com valores velhos dos registradores (dependências RAW não resolvidas), por isso o x13 sai errado quando o programa chega a terminar. As linhas com `laco_sem_hz*.s` usam o mesmo laço, só com 4 `nop` antes do `ecall` para a execução acabar; Cycles e Instrs. retired nessas linhas incluem esses nops e o caminho errado que o laço percorre.

### Prints do pipeline (gerados a partir do relatório do Ripes, processador RV32_5S)

Arquivos em `resultados/ripes/prints/`. Legendas:

```
(a) Pipeline enchendo - RV32 5-stage, laco.s
Os 5 estagios ficam ocupados pela primeira vez no ciclo 4. Antes disso o pipeline esta enchendo.

(b) Bolha por load-use - lw x5 seguido de blt x5
O blt precisa de x5, que o lw so entrega depois de MEM. No ciclo 9 o blt fica parado em ID (e o add em IF): entra uma bolha (nop) em EX e o blt so executa um ciclo depois, ja com x5 via forwarding.

(c) Flush no desvio tomado - blt x12, x11, laco
O blt e decidido em EX (ciclo 14). As 2 instrucoes que ja tinham entrado no pipeline atras dele (addi x17 x0 10; ecall) sao descartadas (cinza com borda vermelha) e nunca chegam a EX. O PC volta para laco.
```

