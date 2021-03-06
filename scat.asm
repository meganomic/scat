BITS 64
default rel
    org 0x400000 ; default virtual address for x86-64

; ELF64 Header
ehdr:
                db 0x7F, "ELF";, 2, 1, 1, 0 ; e_ident[16]
                ;dq 0 ;

_start2:
    mov al, 2 ; 2 bytes - sys_open
    pop rdi ; 1 byte - Pointer to 1st argument or zero
    syscall ; 2 bytes - sys_open
    xchg eax, ebx ; 1 byte - Set RAX to zero and save FD to RBX
    test ebx, ebx ; 2 bytes
    mov al, 1 ; 2 bytes - sys_write
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
    lea esi, [rcx+103] ; 3 bytes - Buffer address
    mov edx, ecx ; 2 bytes - ECX contains the return address of the last syscall. We will use that as the read count.
    mov edi, eax ; 2 bytes - Set EDI to 1 for STDOUT
loop:
    ; This loop alternates between sys_read and sys_write
    xchg eax, ebp ; 1 byte - Switch EAX between 1 and 0 every loop - sys_read <-> sys_write
    xchg edi, ebx ; 2 bytes - Switch EDI between 1 and 3 every loop - Our open file <-> STDOUT
    push rax ; 1 byte - Save RAX since it will be overwritten by the system call
    jmp short loop2 ; 2 bytes
    db 0

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
    pop rdi ; 1 byte - This is the first argument
    jmp short _start2 ; 2 bytes
                ;dd 7 ; p_flags;
                dq 0 ; p_offset;                      /* Segment file offset */
                dq $$ ; p_vaddr;                      /* Segment virtual address */
loop2:
    syscall ; 2 bytes - sys_read and sys_write
    test eax, eax ; 2 bytes
    xchg eax, edx ; 1 byte - Set EDX to how many bytes were Read or Written
    pop rax ; 1 byte - Restore RAX
    jmp short loop3 ; 2 bytes

                ;dq 0 ; p_paddr;                       /* Segment physical address */
                dq end_of_code-$$ ; p_filesz          /* Segment size in file */
                dq end_of_bss-$$ ; p_memsz               /* Segment size in memory */
                ;dq 4096 ; p_align                     /* Segment alignment, file & memory */


loop3:
    jg loop ; Loop until there's an error OR syscall returned 0


exit:
    push byte 60 ; sys_exit
    pop rax
    syscall

    db 0 ; The Program Header needs 8 bytes at the end.

end_of_code:

section .bss
buffer: resb 0x400100

end_of_bss:
