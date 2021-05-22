BITS 64
default rel
    org 0x08048000 ; default virtual address

; ELF64 Header
ehdr:
                db 0x7F, "ELF", 2, 1, 1, 0 ; e_ident[16]
                ;dq 0 ;
_start:
    ; This is where the program starts
    ; Compare Argc against 2, the first argv is the path to the binary
    ; So 2 means the program was given 1 argument
    pop rax ; 1 byte
    pop rdi ; 1 byte
    cmp al, 2 ; 2 bytes
    je short openfile ; 2 bytes
    jmp short perr ; 2 bytes

                dw 2 ; e_type
                dw 62 ; e_machine
                dd 1 ; e_version
                dq _start; e_entry      /* Entry point virtual address */
                dq phdr - $$; e_phoff   /* Program header table file offset */
openfile:
    ; Load the pointer to the 1st 'real' argument aka the filepath into rdi and open it
    ; rax is already 2 here which is sys_open
    pop rdi ; 1 byte - pointer to the path to the file to open
    syscall ; 2 bytes
    test eax, eax ; 2 bytes
perr:
    mov edi, 2 ; 5 bytes
    js short exit ; 2 bytes
    jmp short fstathdr ; 2 bytes

                ;db 0 ; filler byte
                ;dq 0 ; e_shoff          /* Section header table file offset */
                ;dd 0 ; e_flags
                ;dw 64 ; e_ehsize
                dw 56 ; e_phentsize;
                ;dw 1 ; e_phnum;
                ;dw 0 ; e_shentsize;
                ;dw 0 ; e_shnum;
                ;dw 0 ; e_shstrndx;


phdr:
                dd 1 ; p_type;
                dd 7 ; p_flags;
                dq 0 ; p_offset;                      /* Segment file offset */
                dq $$ ; p_vaddr;                      /* Segment virtual address */
fstathdr:
    xchg ebx, eax ; 1 byte - Save FD to ebx and set eax to zero. ebx is zero here
    mov esi, buffer ; 5 bytes - pointer to the buffer
    jmp short fstat ; 2 bytes

                ;dq 0 ; p_paddr;                       /* Segment physical address */
                dq end_of_code-$$ ; p_filesz          /* Segment size in file */
                dq end_of_bss-$$ ; p_memsz               /* Segment size in memory */
                ;dq 4096 ; p_align                     /* Segment alignment, file & memory */


fstat:
    ; Fstat call to get file size
    mov al, 5 ; sys_fstat - This is safe because rax == 0
    mov edi, ebx ; fd
    syscall

    inc edi ; Set exit code

    test eax, eax
    js short exit

    mov r13, [rsi+48] ; load file size


read_loop:
    ; rax is already zero here which is sys_read
    mov edi, ebx ; fd
    mov dx, 65535 ; count
    syscall

    test eax, eax
    js short exit


write:
    ; write syscall
    xchg edx, eax ; amount of bytes read
    mov ax, 1 ; sys_write
    mov dil, 1 ; stdout
    syscall

    ; If there was a error or a short write, exit
    sub eax, edx
    jnz exit

    sub r13, rdx
    jnz short read_loop

    xor edi, edi ; Set exit code to 0


exit:
    xor eax, eax
    mov al, 60 ; sys_exit
    syscall

end_of_code:

section .bss
buffer: resb 65535

end_of_bss:
