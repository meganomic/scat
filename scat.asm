BITS 64
default rel
    org 0x400000 ; default virtual address for x86-64

; ELF64 Header
ehdr:
                db 0x7F, "ELF";, 2, 1, 1, 0 ; e_ident[16]
                ;dq 0 ;

_start:
    ; This is where the program starts
    ; Compare Argc against 2, the first argv is the path to the binary
    ; So 2 means the program was given 1 argument
    pop rax ; 1 byte
    cmp al, 2 ; 2 bytes
    jne short continue ; 2 bytes
    pop rdi ; 1 byte
    pop rdi ; 1 byte
    syscall ; 2 bytes
    xchg eax, ebx
    jmp short openfile1 ; 2 bytes

                dw 2 ; e_type
                dw 62 ; e_machine

openfile1:
    test ebx, ebx ; 2 bytes
    jmp short continue ; 2 bytes
                ;dd 1 ; e_version
                dq _start; e_entry      /* Entry point virtual address */
                dq phdr - $$; e_phoff   /* Program header table file offset */

continue:
    push byte 2 ; 2 bytes
    pop rdi ; 1 byte
    js short exit ; 2 bytes
    mov esi, buffer ; 5 bytes
read:
    mov edi, ebx ; fd
    jmp short read2 ; 2 bytes

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
read2:
    mov edx, ecx ; count - RCX contains the return address of the last system call. Aka 0x04000xx
    syscall
    test eax, eax
    jmp short read_continue

                ;dq 0 ; p_paddr;                       /* Segment physical address */
                dq end_of_code-$$ ; p_filesz          /* Segment size in file */
                dq end_of_bss-$$ ; p_memsz               /* Segment size in memory */
                ;dq 4096 ; p_align                     /* Segment alignment, file & memory */



loop:

    ; write syscall
    xchg edx, eax ; amount of bytes read
    push byte 1 ; sys_write
    pop rax
    mov dil, 1 ; stdout
    syscall

    ; If there was a error or a short write, exit
    sub eax, edx
    jnz short exit

    jmp short read


read_continue:

    js short exit
    jnz short loop


    pop rdi ; Set RDI to zero. There's one on the stack, use that


exit:
    push byte 60 ; sys_exit
    pop rax
    syscall

end_of_code:

section .bss
buffer: resb 0x400100

end_of_bss:
