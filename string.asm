; string.asm
; SSE-accelerated string library for x86-64
; Function: strlen, strcpy, strcmp, strrev, strcat

section .text
	global strlen
	global strcpy
	global strcmp
	global strrev
	global strcat


; strlen(rdi=&str) -> rax=length
; Scan 16 bytes at a time using pcmpeqb to find null byte

strlen:
	pxor xmm0, xmm0		; xmm0 = 16 zero bytes (null comparator)
	mov rax, rdi		; rax = current scan pointer
	mov rcx, rdi		; rcx = base pointer (to compute length at end)

.scan:
	movdqu xmm1, [rax]		; load 16 bytes unaligned
	pcmpeqb xmm1, xmm0		; compare each byte to 0x00
							; 0xFF where null found, 0x00 elsewhere
	pmovmskb edx, xmm1		; extract MSB of each byte lane into rdx
							; rdx is a 16-bit mask, bit set = null found
	test rdx, rdx			; any null byte in these 16?
	jnz .found				; yes - find exact position
	add rax, 16				; no - advance 16 bytes
	jmp .scan

.found:
	bsf rdx, rdx			; bit scan forward - find index of the first set bit
							; rdx = byte offset of null within the 16-byte chunk
	add rax, rdx			; rax = pointer to null terminator
	sub rax, rcx			; length = null position - base position
	ret


; strcpy(rdi=&dst, rsi=&src) -> rax=&dst
; copy 16 bytes at a time, stop when chunk contains null

strcpy:
	pxor xmm0, xmm0			; xmm0 = null comparator
	mov rax, rdi			; save dst base for return value
	mov rcx, rsi			; rcx = src pointer
	mov rdx, rdi			; rdx = dst pointer

.copy_loop:
	movdqu xmm1, [rcx]		; load 16 bytes from src
	movdqu [rdx], xmm1		; store 16 bytes to dst
	pcmpeqb xmm1, xmm0		; check for null byte in the chunk just copied
	pmovmskb r8d, xmm1		; r8 = null mask
	test r8, r8
	jnz .copy_done			; null found - stop
	add rcx, 16				; advance src
	add rdx, 16				; advance dst
	jmp .copy_loop

.copy_done:
	ret 					; rax still holds &dst


; strcmp(rdi=&a, rsi=&b) -> rax: 0=equal, 1=a>b, -1=a<b
; compare 16 bytes at a time, fall back to scalar on mismatch

strcmp:
	pxor xmm0, xmm0			; null comparator

.cmp_loop:
	movdqu xmm1, [rdi]		; load 16 bytes from a
	movdqu xmm2, [rsi]		; load 16 bytes from b
	pcmpeqb xmm3, xmm0		; check for null character
	pmovmskb eax, xmm3
	test rax, rax
	jnz .scalar_cmp			; null in a - fall back to scalar

	; Compare a chunk vs b chunk
	pcmpeqb xmm1, xmm2		; xmm1 = 0xFF where bytes match, 0x00 where they differ
	pmovmskb eax, xmm1
	cmp rax, 0xFFFF			; all 16 bytes matched?
	jne .scalar_cmp			; mismatch somewhere - fall back to scalar
	add rdi, 16
	add rsi, 16
	jmp .cmp_loop

.scalar_cmp:
	; Byte-by-byte comparison from current pointer position
	movzx rax, byte [rdi]	; load byte from a (zero-extended)
	movzx rcx, byte [rsi]	; load byte from b (zero-extended)
	cmp al, cl
	ja .greater				; a > b
	jb .less				; a < b
	test al, al				; both equal - are we at null?
	jz .equal				; yes - strings are equal
	inc rdi
	inc rsi
	jmp .scalar_cmp

.equal:
	xor rax, rax			; return 0
	ret

.greater:
	mov rax, 1				; return 1
	ret

.less:
	mov rax, -1				; return -1
	ret


; strrev(rdi=&str) -> rax=&str (in-place reversal)
; scalar - find end eith strlen, then swap from both ends inward
strrev:
	mov rax, rdi			; save base for return value
	push rdi				; preserve rdi across call
	call strlen				; rax = length of string
	pop rdi					; restore base pointer

	test rax, rax			; empty string? nothing to do
	jz .rev_done

	lea rsi, [rdi + rax- 1]	; rsi = pointer to last char (before null)
	mov rdx, rdi			; rdx = pointer to first char

.swap_loop:
	cmp rdx, rsi			; have the two pointers met or crossed?
	jge .rev_done

	mov al, [rdx]			; al = left char
	mov cl, [rsi]			; cl = right char
	mov [rdx], cl			; write right char to left position
	mov [rsi], al			; write left char to right position

	inc rdx					; move left pointer right
	dec rsi					; mov right pointer left
	jmp .swap_loop

.rev_done:
	mov rax, rdi			; return &str
	ret


; strcat(rdi=&dst, rsi=&src) -> rax=&dst
; find end of the dst with strlen, then strcpy scr there
strcat:
	mov r12, rdi			; save dst base in callee-saved register
	push r12				; preserve r12
	push rsi				; preserve src

	mov rdi, r12			; strlen(dst)
	call strlen				; rax = length

	pop rsi					; restore src
	add r12, rax			; r12 now = end of dst (null position)
	mov rdi, r12			; dst for strcpy = end of dst
	call strcpy				; strcpy(end_of_dst, src)

	pop r12					; restore r12
	mov rax, rdi			; return original dst base
	ret
