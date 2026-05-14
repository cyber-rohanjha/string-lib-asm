; main.asm
; Entry point - calls each string function and stores results for GDB verification

default rel

extern strlen
extern strcpy
extern strcmp
extern strrev
extern strcat

extern str_a
extern str_b
extern str_c
extern str_rev
extern str_dst
extern str_cat
extern str_cat_src
extern strlen_res
extern strcmp_res

section .text
	global _start

_start:
	
	; strlen
	; strlen(str_a) - expect 13 ("Hello, world!" = 13 chars)
	lea rdi, [str_a]
	call strlen
	lea rcx, [strlen_res]
	mov [rcx], rax			; store result for GDB inspection

	; strcpy
	; strcpy(str_dst, str_a) - str_dst should contain "Hello, World!"
	lea rdi, [str_dst]
	lea rsi, [str_a]
	call strcpy

	; strcmp equal case
	; strcmp(str_a, str_b) - expect 0 (both "Hello, World!")
	lea rdi, [str_a]
	lea rsi, [str_b]
	call strcmp
	lea rcx, [strcmp_res]
	mov [rcx], rax			; store result for GDB insepction

	; strcmp unequal case
	; strcmp(str_a, str_c) - expect 1 (str_a > str_c: 'W' > 'G')
	lea rdi, [str_a]
	lea rsi, [str_c]
	call strcmp
	lea rcx, [strcmp_res]
	mov [rcx], rax

	; strrev
	; strrev(str_rev) - "abcdef" -> "fedcba" in place
	lea rdi, [str_rev]
	call strrev

	; strcat
	; strcat(str_cat, str_cat_src) - "Hello, " + "World!" -> "Hello, World!"
	lea rdi, [str_cat]
	lea rsi, [str_cat_src]
	call strcat

	; Exit
	mov rax, 60
	xor rdi, rdi
	syscall
