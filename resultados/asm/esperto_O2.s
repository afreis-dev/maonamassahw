	.file	"branch.c"
	.text
	.p2align 4
	.type	cmp, @function
cmp:
.LFB54:
	.cfi_startproc
	endbr64
	movl	(%rsi), %eax
	cmpl	%eax, (%rdi)
	setg	%al
	setl	%dl
	movzbl	%dl, %edx
	movzbl	%al, %eax
	subl	%edx, %eax
	ret
	.cfi_endproc
.LFE54:
	.size	cmp, .-cmp
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"ordenado"
.LC1:
	.string	"aleatorio"
.LC2:
	.string	"sort"
.LC3:
	.string	"sem mem\303\263ria\n"
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align 8
.LC6:
	.string	"modo=%-9s limiar=%d repeticoes=%d soma=%lld tempo=%.3f s\n"
	.section	.text.startup,"ax",@progbits
	.p2align 4
	.globl	main
	.type	main, @function
main:
.LFB55:
	.cfi_startproc
	endbr64
	pushq	%r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	pushq	%r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	pushq	%r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	pushq	%r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	pushq	%rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	subq	$8, %rsp
	.cfi_def_cfa_offset 64
	cmpl	$1, %edi
	jle	.L23
	movl	%edi, %ebp
	movq	8(%rsi), %rdi
	movq	%rsi, %rbx
	leaq	.LC2(%rip), %rsi
	xorl	%r14d, %r14d
	movl	$10000, %r12d
	call	strcmp@PLT
	testl	%eax, %eax
	sete	%r14b
	cmpl	$2, %ebp
	jne	.L37
.L4:
	movl	$131072, %edi
	call	malloc@PLT
	movq	%rax, %rbp
	testq	%rax, %rax
	je	.L38
	leaq	131072(%rax), %r15
	movq	%rax, %rbx
	.p2align 4
	.p2align 3
.L7:
	call	rand@PLT
	addq	$4, %rbx
	cltd
	shrl	$24, %edx
	addl	%edx, %eax
	movzbl	%al, %eax
	subl	%edx, %eax
	movl	%eax, -4(%rbx)
	cmpq	%r15, %rbx
	jne	.L7
	testl	%r14d, %r14d
	jne	.L39
	call	clock@PLT
	movq	%rax, %r13
	testl	%r12d, %r12d
	jle	.L40
.L21:
	cmpl	$3, %r12d
	jle	.L41
	movl	%r12d, %ecx
	pxor	%xmm6, %xmm6
	pcmpeqd	%xmm8, %xmm8
	xorl	%edx, %edx
	shrl	$2, %ecx
	psrld	$25, %xmm8
	movdqa	%xmm6, %xmm5
.L13:
	movq	%rbp, %rax
	.p2align 4
	.p2align 3
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
	addl	$1, %edx
	cmpl	%ecx, %edx
	jne	.L13
	paddq	%xmm6, %xmm5
	movl	%r12d, %esi
	movdqa	%xmm5, %xmm0
	andl	$-4, %esi
	psrldq	$8, %xmm0
	paddq	%xmm0, %xmm5
	movq	%xmm5, %rbx
	testb	$3, %r12b
	je	.L14
.L16:
	movq	%rbp, %rax
	.p2align 5
	.p2align 4
	.p2align 3
.L15:
	movslq	(%rax), %rdx
	movq	%rdx, %rcx
	addq	%rbx, %rdx
	cmpl	$127, %ecx
	cmovg	%rdx, %rbx
	addq	$4, %rax
	cmpq	%r15, %rax
	jne	.L15
	addl	$1, %esi
	cmpl	%esi, %r12d
	jg	.L16
.L14:
	call	clock@PLT
	pxor	%xmm0, %xmm0
	leaq	.LC1(%rip), %rdx
	subq	%r13, %rax
	testl	%r14d, %r14d
	cvtsi2sdq	%rax, %xmm0
	leaq	.LC0(%rip), %rax
	divsd	.LC5(%rip), %xmm0
	cmovne	%rax, %rdx
.L20:
	movq	%rbx, %r9
	movl	%r12d, %r8d
	movl	$128, %ecx
	leaq	.LC6(%rip), %rsi
	movl	$2, %edi
	movl	$1, %eax
	call	__printf_chk@PLT
	movq	%rbp, %rdi
	call	free@PLT
	xorl	%eax, %eax
.L3:
	addq	$8, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	ret
.L37:
	.cfi_restore_state
	movq	16(%rbx), %rdi
	movl	$10, %edx
	xorl	%esi, %esi
	call	__isoc23_strtol@PLT
	movl	%eax, %r12d
	jmp	.L4
.L23:
	xorl	%r14d, %r14d
	movl	$10000, %r12d
	jmp	.L4
.L39:
	leaq	cmp(%rip), %rcx
	movl	$4, %edx
	movl	$32768, %esi
	movq	%rbp, %rdi
	call	qsort@PLT
	call	clock@PLT
	movq	%rax, %r13
	testl	%r12d, %r12d
	jg	.L21
	call	clock@PLT
	pxor	%xmm0, %xmm0
	xorl	%ebx, %ebx
	leaq	.LC0(%rip), %rdx
	subq	%r13, %rax
	cvtsi2sdq	%rax, %xmm0
	divsd	.LC5(%rip), %xmm0
	jmp	.L20
.L41:
	xorl	%esi, %esi
	xorl	%ebx, %ebx
	jmp	.L16
.L40:
	call	clock@PLT
	pxor	%xmm0, %xmm0
	xorl	%ebx, %ebx
	leaq	.LC1(%rip), %rdx
	subq	%r13, %rax
	cvtsi2sdq	%rax, %xmm0
	divsd	.LC5(%rip), %xmm0
	jmp	.L20
.L38:
	movq	stderr(%rip), %rcx
	movl	$13, %edx
	movl	$1, %esi
	leaq	.LC3(%rip), %rdi
	call	fwrite@PLT
	movl	$1, %eax
	jmp	.L3
	.cfi_endproc
.LFE55:
	.size	main, .-main
	.section	.rodata.cst8,"aM",@progbits,8
	.align 8
.LC5:
	.long	0
	.long	1093567616
	.ident	"GCC: (Ubuntu 15.2.0-16ubuntu1) 15.2.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	1f - 0f
	.long	4f - 1f
	.long	5
0:
	.string	"GNU"
1:
	.align 8
	.long	0xc0000002
	.long	3f - 2f
2:
	.long	0x3
3:
	.align 8
4:
