	.file	"branchless.c"
	.text
	.type	cmp, @function
cmp:
.LFB54:
	.cfi_startproc
	endbr64
	movl	(%rsi), %eax
	cmpl	%eax, (%rdi)
	setg	%al
	movzbl	%al, %eax
	setl	%dl
	movzbl	%dl, %edx
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
.LC5:
	.string	"modo=%-9s limiar=%d repeticoes=%d soma=%lld tempo=%.3f s\n"
	.text
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
	jle	.L15
	movl	%edi, %ebp
	movq	%rsi, %rbx
	movq	8(%rsi), %rdi
	leaq	.LC2(%rip), %rsi
	call	strcmp@PLT
	testl	%eax, %eax
	sete	%r15b
	movzbl	%r15b, %r15d
	movl	$10000, %r12d
	cmpl	$2, %ebp
	jle	.L3
	movq	16(%rbx), %rdi
	movl	$10, %edx
	movl	$0, %esi
	call	__isoc23_strtol@PLT
	movl	%eax, %r12d
	jmp	.L3
.L15:
	movl	$0, %r15d
	movl	$10000, %r12d
.L3:
	movl	$131072, %edi
	call	malloc@PLT
	movq	%rax, %r13
	testq	%rax, %rax
	je	.L22
	leaq	131072(%rax), %rbp
	movq	%rax, %rbx
.L6:
	call	rand@PLT
	cltd
	shrl	$24, %edx
	addl	%edx, %eax
	movzbl	%al, %eax
	subl	%edx, %eax
	movl	%eax, (%rbx)
	addq	$4, %rbx
	cmpq	%rbp, %rbx
	jne	.L6
	testl	%r15d, %r15d
	jne	.L23
	call	clock@PLT
	movq	%rax, %r14
	testl	%r12d, %r12d
	jle	.L24
.L13:
	movl	$0, %esi
	movl	$0, %ebx
	movl	$0, %ecx
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
	addl	$1, %esi
	cmpl	%esi, %r12d
	jg	.L9
	call	clock@PLT
	subq	%r14, %rax
	pxor	%xmm0, %xmm0
	cvtsi2sdq	%rax, %xmm0
	divsd	.LC4(%rip), %xmm0
	leaq	.LC1(%rip), %rdx
	testl	%r15d, %r15d
	leaq	.LC0(%rip), %rax
	cmovne	%rax, %rdx
.L12:
	movq	%rbx, %r9
	movl	%r12d, %r8d
	movl	$128, %ecx
	leaq	.LC5(%rip), %rsi
	movl	$2, %edi
	movl	$1, %eax
	call	__printf_chk@PLT
	movq	%r13, %rdi
	call	free@PLT
	movl	$0, %eax
.L2:
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
.L22:
	.cfi_restore_state
	movq	stderr(%rip), %rcx
	movl	$13, %edx
	movl	$1, %esi
	leaq	.LC3(%rip), %rdi
	call	fwrite@PLT
	movl	$1, %eax
	jmp	.L2
.L23:
	leaq	cmp(%rip), %rcx
	movl	$4, %edx
	movl	$32768, %esi
	movq	%r13, %rdi
	call	qsort@PLT
	call	clock@PLT
	movq	%rax, %r14
	testl	%r12d, %r12d
	jg	.L13
	call	clock@PLT
	subq	%r14, %rax
	pxor	%xmm0, %xmm0
	cvtsi2sdq	%rax, %xmm0
	divsd	.LC4(%rip), %xmm0
	movl	$0, %ebx
	leaq	.LC0(%rip), %rdx
	jmp	.L12
.L24:
	call	clock@PLT
	subq	%r14, %rax
	pxor	%xmm0, %xmm0
	cvtsi2sdq	%rax, %xmm0
	divsd	.LC4(%rip), %xmm0
	movl	$0, %ebx
	leaq	.LC1(%rip), %rdx
	jmp	.L12
	.cfi_endproc
.LFE55:
	.size	main, .-main
	.section	.rodata.cst8,"aM",@progbits,8
	.align 8
.LC4:
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
