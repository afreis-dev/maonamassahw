/*
 * Aula 10 — Pipeline MIPS, Hazards e Previsão de Desvio
 * Infraestrutura de Hardware — CESAR School — 2026.2
 *
 * Experimento do array ordenado: o MESMO laço, com os MESMOS dados,
 * fica várias vezes mais rápido quando o array está ordenado.
 * A conta é idêntica — a CPU só para de errar a previsão do desvio.
 *
 * Compilar:  gcc -O1 -o branch branch.c
 * Rodar:     ./branch                 # array ALEATÓRIO
 *            ./branch sort            # array ORDENADO
 *            ./branch sort 2000       # opcional: nº de repetições (padrão 10000)
 *
 * Medir a causa (somente Linux):
 *            perf stat -e branches,branch-misses ./branch
 *            perf stat -e branches,branch-misses ./branch sort
 *
 * Trocar o limiar sem editar o código:
 *            gcc -O1 -DLIMIAR=250 -o branch branch.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define N 32768                 /* tamanho do array                      */

#ifndef LIMIAR
#define LIMIAR 128              /* soma apenas os valores >= LIMIAR      */
#endif

#ifndef REPETICOES
#define REPETICOES 10000        /* repete o laço para o efeito aparecer  */
#endif

/*
 * BARREIRA: uma instrução assembly vazia. Não gera código nenhum, mas o
 * compilador não pode "adiantar" nem eliminar o que está dentro do if.
 *
 * Por que precisamos dela? O compilador é esperto: com -O1 ou mais, ele
 * costuma transformar sozinho o "if (...) soma += v[i]" em código SEM
 * desvio (instrução cmov no x86, csel no ARM). Aí o desvio some e o
 * experimento não mostra nada. Com a barreira, o desvio continua lá.
 *
 * Para ver o compilador fazendo isso:  gcc -O2 -DSEM_BARREIRA ...
 */
#ifdef SEM_BARREIRA
#define BARREIRA()
#else
#define BARREIRA() __asm__ volatile("")
#endif

/* comparador crescente para o qsort */
static int cmp(const void *a, const void *b) {
    int x = *(const int *)a;
    int y = *(const int *)b;
    return (x > y) - (x < y);
}

int main(int argc, char **argv) {
    int ordenar = (argc > 1 && strcmp(argv[1], "sort") == 0);
    int repeticoes = (argc > 2) ? atoi(argv[2]) : REPETICOES;

    int *v = malloc(N * sizeof(int));
    if (v == NULL) {
        fprintf(stderr, "sem memória\n");
        return 1;
    }

    /* sem srand(): a sequência é sempre a mesma -> experimento reprodutível */
    for (int i = 0; i < N; i++)
        v[i] = rand() % 256;                    /* valores de 0 a 255 */

    /* Se pedir "sort", ORDENA antes de medir (o tempo do sort não conta) */
    if (ordenar)
        qsort(v, N, sizeof(int), cmp);

    clock_t ini = clock();
    long long soma = 0;
    for (int r = 0; r < repeticoes; r++)        /* repete p/ o efeito aparecer */
        for (int i = 0; i < N; i++)
            if (v[i] >= LIMIAR) {               /* <-- O DESVIO CRÍTICO */
                BARREIRA();
                soma += v[i];
            }
    clock_t fim = clock();

    printf("modo=%-9s limiar=%d repeticoes=%d soma=%lld tempo=%.3f s\n",
           ordenar ? "ordenado" : "aleatorio", LIMIAR, repeticoes, soma,
           (double)(fim - ini) / CLOCKS_PER_SEC);

    free(v);
    return 0;
}
