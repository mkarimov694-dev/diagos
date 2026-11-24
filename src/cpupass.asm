; cpupass.asm - паспорт процессора
; сборка: nasm -f elf64 cpupass.asm -o cpupass.o && ld cpupass.o -o cpupass

%macro PRINTS 1+
    jmp %%after
%%s:  db %1
%%len equ $ - %%s
%%after:
    mov eax, 1
    mov edi, 1
    lea rsi, [rel %%s]
    mov edx, %%len
    syscall
%endmacro

%macro FEAT 3
    bt %1, %2
    jnc %%skip
    PRINTS %3
%%skip:
%endmacro

section .bss
    vendor  resb 13
    brand   resb 49
    numbuf  resb 24

section .text
global _start

_start:
    PRINTS "===== ПАСПОРТ ПРОЦЕССОРА =====", 10

    PRINTS "Производитель : "
    xor eax, eax
    cpuid
    mov [vendor],   ebx
    mov [vendor+4], edx
    mov [vendor+8], ecx
    mov byte [vendor+12], 10
    mov eax, 1
    mov edi, 1
    lea rsi, [rel vendor]
    mov edx, 13
    syscall

    PRINTS "Модель        : "
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000004
    jb  .nobrand
    lea r8, [rel brand]
    mov r9d, 0x80000002
.bl:
    mov eax, r9d
    cpuid
    mov [r8],    eax
    mov [r8+4],  ebx
    mov [r8+8],  ecx
    mov [r8+12], edx
    add r8, 16
    inc r9d
    cmp r9d, 0x80000005
    jb  .bl
    mov byte [brand+48], 10
    mov eax, 1
    mov edi, 1
    lea rsi, [rel brand]
    mov edx, 49
    syscall
    jmp .info
.nobrand:
    PRINTS "не определена", 10

.info:
    mov eax, 1
    cpuid
    mov r14d, eax
    mov r15d, ebx
    mov r12d, ecx
    mov r13d, edx

    PRINTS "Family        : "
    mov eax, r14d
    shr eax, 8
    and eax, 0xF
    cmp eax, 0xF
    jne .fam_ok
    mov edx, r14d
    shr edx, 20
    and edx, 0xFF
    add eax, edx
.fam_ok:
    call print_dec

    PRINTS "Model         : "
    mov eax, r14d
    shr eax, 4
    and eax, 0xF
    mov ecx, r14d
    shr ecx, 8
    and ecx, 0xF
    cmp ecx, 6
    je  .ext
    cmp ecx, 0xF
    jne .mod_ok
.ext:
    mov edx, r14d
    shr edx, 16
    and edx, 0xF
    shl edx, 4
    add eax, edx
.mod_ok:
    call print_dec

    PRINTS "Stepping      : "
    mov eax, r14d
    and eax, 0xF
    call print_dec

    PRINTS "Лог. процессоров: "
    mov eax, r15d
    shr eax, 16
    and eax, 0xFF
    call print_dec

    PRINTS "Возможности   : "
    FEAT r13d, 25, "SSE "
    FEAT r13d, 26, "SSE2 "
    FEAT r12d, 0,  "SSE3 "
    FEAT r12d, 19, "SSE4.1 "
    FEAT r12d, 20, "SSE4.2 "
    FEAT r12d, 25, "AES "
    FEAT r12d, 28, "AVX "
    FEAT r12d, 5,  "VMX(виртуализация) "
    FEAT r13d, 28, "HTT "
    PRINTS 10

    mov eax, 60
    xor edi, edi
    syscall

print_dec:
    lea rsi, [rel numbuf+20]
    mov byte [rsi], 10
    mov ebx, 10
.dl:
    xor edx, edx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .dl
    lea rdx, [rel numbuf+21]
    sub rdx, rsi
    mov eax, 1
    mov edi, 1
    syscall
    ret
