section .data
	global str_a
	global str_b
	global str_c
	global str_rev
	global str_dst
	global str_cat
	global str_cat_src

	str_a:		db "Hello, World!", 0
	str_b:		db "Hello, World!", 0
	str_c:		db "Hello, GitHub!", 0
	str_rev:	db "abcdef", 0
	str_dst:	times 64 db 0
	str_cat:	db "Hello, ", 0
	str_cat_src:db "World!", 0

section .bss
	global strlen_res
	global strcmp_res

	strlen_res: resq 1
	strcmp_res: resq 1
