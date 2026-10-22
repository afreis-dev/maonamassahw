.data
v:  .word 3, 7, 13, 90, 128, 150, 200, 255

.text
main:
    la   x10, v
    li   x11, 8
    li   x12, 0
    li   x13, 0
    li   x14, 128

laco:
    lw   x5, 0(x10)
    blt  x5, x14, pula
    add  x13, x13, x5
pula:
    addi x10, x10, 4
    addi x12, x12, 1
    blt  x12, x11, laco

fim:
    li   a7, 10
    ecall
