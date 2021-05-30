BITS 64
default rel
    org 0x400000 ; default virtual address for x86-64

; ELF64 Header
ehdr:
                db 0x7F, "ELF";, 2, 1, 1, 0 ; e_ident[16]
                ;dq 0 ;

_start2:
    mov al, 2 ; 2 bytes
    pop rdi ; 1 byte - Filename pointer or Zero
    syscall ; 2 bytes
    xchg eax, ebx ; 1 byte - Set RAX to zero and save FD to RBX
    test ebx, ebx ; 2 bytes
    mov al, 1 ; 2 bytes - This is setting up for the read/write loop
    jmp short openfile1 ; 2 bytes

                dw 2 ; e_type
                dw 62 ; e_machine

openfile1:
    js short exit ; 2 bytes
    jmp short continue ; 2 bytes
                ;dd 1 ; e_version
                dq _start; e_entry      /* Entry point virtual address */
                dq phdr - $$; e_phoff   /* Program header table file offset */

continue:
    mov esi, buffer ; 5 bytes
    mov edx, ecx ; 2 bytes - This is setting up for the read/write loop
    mov edi, eax ; 2 bytes - This is setting up for the read/write loop
loop:
    xchg eax, ebp ; 1 byte
    xchg edi, ebx ; 2 bytes
    jmp short loop2 ; 2 bytes

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
_start:
    ; I can put this here because 'pop rdi' is 0x5F which sets the correct permissions
    pop rdi ; 1 byte
    pop rdi ; 1 byte
    jmp short _start2 ; 2 bytes
                ;dd 7 ; p_flags;
                dq 0 ; p_offset;                      /* Segment file offset */
                dq $$ ; p_vaddr;                      /* Segment virtual address */
loop2:
    push rax ; 1 byte
    syscall ; 2 bytes
    test eax, eax ; 2 bytes
    xchg eax, edx
    jmp short loop3 ; 2 bytes

                ;dq 0 ; p_paddr;                       /* Segment physical address */
                dq end_of_code-$$ ; p_filesz          /* Segment size in file */
                dq end_of_bss-$$ ; p_memsz               /* Segment size in memory */
                ;dq 4096 ; p_align                     /* Segment alignment, file & memory */


loop3:
    pop rax ; 1 byte
    jg loop


exit:
    push byte 60 ; sys_exit
    pop rax
    syscall

end_of_code:

section .bss
buffer: resb 0x400100

end_of_bss:
