# Aula 10 — demonstração do professor
#
#   make              compila ./branch (com -O1, como no slide)
#   make demo         roda aleatório x ordenado (5x cada, mediana) e perf se houver
#   make perf         só a medição com perf (Linux)
#   make asm          gera branch.s e branch_sem_barreira.s para comparar o Assembly
#   make esperto      mostra o compilador eliminando o desvio sozinho (-O2, sem barreira)
#   make clean

CC     ?= gcc
CFLAGS ?= -O1 -Wall

all: branch

branch: branch.c
	$(CC) $(CFLAGS) -o $@ $<

demo: branch
	./medir.sh ./branch

perf: branch
	perf stat -e branches,branch-misses ./branch
	perf stat -e branches,branch-misses ./branch sort

asm: branch.c
	$(CC) -O1 -S -o branch.s $<
	$(CC) -O1 -S -DSEM_BARREIRA -o branch_sem_barreira.s $<
	@echo "Procure o laço em branch_sem_barreira.s: cmov (x86) ou csel (ARM) no lugar do desvio."

esperto: branch.c
	$(CC) -O2 -DSEM_BARREIRA -o branch_esperto $<
	./branch_esperto
	./branch_esperto sort

clean:
	rm -f branch branch_esperto *.s *.o

.PHONY: all demo perf asm esperto clean
