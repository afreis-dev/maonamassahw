#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define N 32768

#ifndef LIMIAR
#define LIMIAR 128
#endif

#ifndef REPETICOES
#define REPETICOES 10000
#endif

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

    for (int i = 0; i < N; i++)
        v[i] = rand() % 256;

    if (ordenar)
        qsort(v, N, sizeof(int), cmp);

    clock_t ini = clock();
    long long soma = 0;
    for (int r = 0; r < repeticoes; r++)
        for (int i = 0; i < N; i++) {
            int mascara = -(v[i] >= LIMIAR);
            soma += v[i] & mascara;
        }
    clock_t fim = clock();

    printf("modo=%-9s limiar=%d repeticoes=%d soma=%lld tempo=%.3f s\n",
           ordenar ? "ordenado" : "aleatorio", LIMIAR, repeticoes, soma,
           (double)(fim - ini) / CLOCKS_PER_SEC);

    free(v);
    return 0;
}
