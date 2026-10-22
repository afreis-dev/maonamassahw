#include <linux/perf_event.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static int abrir(unsigned long long evento, pid_t pid) {
    struct perf_event_attr pe;
    memset(&pe, 0, sizeof pe);
    pe.type = PERF_TYPE_HARDWARE;
    pe.size = sizeof pe;
    pe.config = evento;
    pe.disabled = 1;
    pe.enable_on_exec = 1;
    pe.exclude_kernel = 1;
    pe.exclude_hv = 1;
    return (int)syscall(SYS_perf_event_open, &pe, pid, -1, -1, 0);
}

static long long ler(int fd) {
    long long valor = -1;
    if (read(fd, &valor, sizeof valor) != (ssize_t)sizeof valor)
        return -1;
    return valor;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "uso: %s comando [argumentos]\n", argv[0]);
        return 2;
    }

    int sinal[2];
    if (pipe(sinal) < 0) {
        perror("pipe");
        return 1;
    }

    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }
    if (pid == 0) {
        char c;
        close(sinal[1]);
        if (read(sinal[0], &c, 1) != 1)
            _exit(127);
        close(sinal[0]);
        execvp(argv[1], argv + 1);
        perror(argv[1]);
        _exit(127);
    }

    close(sinal[0]);
    int fb = abrir(PERF_COUNT_HW_BRANCH_INSTRUCTIONS, pid);
    int fm = abrir(PERF_COUNT_HW_BRANCH_MISSES, pid);
    if (fb < 0 || fm < 0) {
        perror("perf_event_open");
        kill(pid, SIGKILL);
        waitpid(pid, NULL, 0);
        return 1;
    }

    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    if (write(sinal[1], "x", 1) != 1) {
        perror("write");
        kill(pid, SIGKILL);
        waitpid(pid, NULL, 0);
        return 1;
    }
    close(sinal[1]);

    int status = 0;
    waitpid(pid, &status, 0);
    clock_gettime(CLOCK_MONOTONIC, &t1);

    long long branches = ler(fb);
    long long misses = ler(fm);
    double segundos = (double)(t1.tv_sec - t0.tv_sec) + (double)(t1.tv_nsec - t0.tv_nsec) / 1e9;

    fprintf(stderr, "\n Performance counter stats for '");
    for (int i = 1; i < argc; i++)
        fprintf(stderr, "%s%s", i > 1 ? " " : "", argv[i]);
    fprintf(stderr, "':\n\n");
    fprintf(stderr, "%16lld      branches\n", branches);
    fprintf(stderr, "%16lld      branch-misses     #  %6.2f%% of all branches\n", misses,
            branches > 0 ? 100.0 * (double)misses / (double)branches : 0.0);
    fprintf(stderr, "\n%16.6f seconds time elapsed\n\n", segundos);

    return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
}
