# x86-64 Assembly String Library

A low-level string library written in x86-64 NASM assembly, implementing common string operations using SSE/SIMD instructions for efficient byte-level processing.

---

## Motivation

A continuation of the ==x86-64 Assembly Math Library== this project implements standard string operations at the hardware level — no libc, no compiler abstractions, just raw SSE instructions and registers.

---

## Files

### `string.asm`
Implements five string operations. SSE is used wherever a 16-byte-at-a-time scan or copy is beneficial.

| Function | Signature | Returns | Strategy |
|---|---|---|---|
| `strlen` | `rdi=&str` | `rax = length` | `pcmpeqb` + `pmovmskb` — scans 16 bytes at a time for null |
| `strcpy` | `rdi=&dst, rsi=&src` | `rax = &dst` | `movdqu` — copies 16 bytes at a time, stops on null |
| `strcmp` | `rdi=&a, rsi=&b` | `rax = 0 / 1 / -1` | SSE 16-byte compare, falls back to scalar on mismatch |
| `strrev` | `rdi=&str` | `rax = &str` | Scalar two-pointer swap from both ends inward |
| `strcat` | `rdi=&dst, rsi=&src` | `rax = &dst` | Finds end of dst via `strlen`, then `strcpy` from there |

---

### `data.asm`
All static string data and result buffers.

| Symbol | Type | Description |
|---|---|---|
| `str_a` | `db` | Primary test string — `"Hello, World!"` |
| `str_b` | `db` | Equal to `str_a` — used for `strcmp` equal case |
| `str_c` | `db` | `"Hello, Kali!"` — used for `strcmp` unequal case |
| `str_rev` | `db` | `"abcdef"` — input for `strrev` |
| `str_dst` | `times 64 db` | Output buffer for `strcpy` |
| `str_cat` | `db` | `"Hello, "` — base string for `strcat` |
| `str_cat_src` | `db` | `"World!"` — appended by `strcat` |
| `strlen_res` | `resq` | Stores `strlen` return value |
| `strcmp_res` | `resq` | Stores `strcmp` return value |

---

### `main.asm`
Entry point that calls each function in sequence and stores results in memory for verification.

| Operation | Input | Expected Result |
|---|---|---|
| `strlen` | `str_a` | `13` |
| `strcpy` | `str_dst ← str_a` | `str_dst = "Hello, World!"` |
| `strcmp` equal | `str_a, str_b` | `0` |
| `strcmp` unequal | `str_a, str_c` | `1` (`'W' > 'K'`) |
| `strrev` | `str_rev` | `"fedcba"` |
| `strcat` | `str_cat + str_cat_src` | `"Hello, World!"` |

---

## Output

This is a computational string library — no output is printed to the screen. All operations run silently and store their results in memory. To verify correctness, use GDB:

```bash
gdb ./stringlib
break *<addr of mov $0x3c, %rax>   # break just before exit syscall
run
```

To find the exit instruction address:
```bash
gdb ./stringlib
break _start
run
disassemble _start    # look for 'mov $0x3c, %rax'
```

Then inspect each result — **break and step immediately after each call** rather than waiting until the exit breakpoint, since internal calls (e.g. `strrev` calling `strlen`) may overwrite result buffers:

```gdb
x/1dg &strlen_res      # expect 13
x/s   &str_dst         # expect "Hello, World!"
x/1dg &strcmp_res      # expect 1
x/s   &str_rev         # expect "fedcba"
x/s   &str_cat         # expect "Hello, World!"
```

---

## Build Instructions

```bash
make
./stringlib
```

To clean and rebuild from scratch:
```bash
make clean
make
```

> Requires [NASM](https://www.nasm.us/) and a Linux x86-64 environment.

---

## Architecture Notes

- All functions follow the **System V AMD64 ABI** calling convention.
- Strings are null-terminated. All SSE scan loops search for the null byte `0x00`.
- SSE instructions used: `pxor`, `movdqu`, `pcmpeqb`, `pmovmskb`, `bsf`.
- `strrev` and `strcat` call `strlen` internally — callee-saved registers (`r12`) are used to preserve pointers across internal calls.
- `default rel` is set in `main.asm` for correct RIP-relative symbol resolution across object files.
- Unlike the math library, no `align 16` is required here since `movdqu` (unaligned) is used instead of `movdqa`/`movaps`.
