BITS 64
default rel
    org 0x08048000 ; default virtual address

; ELF64 Header
ehdr:
                db 0x7F, "ELF", 2, 1, 1;, 0 ; e_ident[16]
                ;dq 0 ;
_start:
    mov eax, [rsp] ; 3 bytes
    cmp al, 2 ; 2 bytes
    je short openfile ; 2 bytes
    jmp short perr ; 2 bytes
                dw 2 ; e_type
                dw 62 ; e_machine
                dd 1 ; e_version
                dq _start; e_entry      /* Entry point virtual address */
                dq phdr - $$; e_phoff   /* Program header table file offset */
openfile:
    mov rdi, [rsp+16] ; 5 bytes
    syscall ; 2 bytes
    test eax, eax ; 2 bytes
    jmp short openfile_continue ; 2 bytes
                db 0 ; filler byte
                ;dq 0 ; e_shoff          /* Section header table file offset */
                ;dd 0 ; e_flags
                dw 64 ; e_ehsize
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
perr:
    push str1
    pop rsp
    jmp short err ; 2 bytes
                ;dq 0 ; p_paddr;                       /* Segment physical address */
                dq end_of_code-$$ ; p_filesz          /* Segment size in file */
                dq end_of_bss-$$ ; p_memsz               /* Segment size in memory */
                dq 4096 ; p_align                     /* Segment alignment, file & memory */


err:
    jmp short exit_print_error
    str1: db `scat [filename] \n`


openfile_continue:
    push estr
    pop rsp

    mov [rsp+8], byte 50 ; Set syscall number in error string

    js short exit_print_error


fstat:
    mov bl, al ; Save fd - fd won't be above 255. I'll eat my shoes if it is

    mov [rsp+8], byte 53 ; Set syscall number in error string

    ; Fstat call to get file size
    lea esi, buffer
    mov al, 5 ; sys_fstat
    mov edi, ebx ; fd - This is safe because it resets upper bits
    syscall

    test eax, eax
    js short exit_print_error


no_error:
    mov r13, [rsi+48] ; load file size


read_loop:
    ; rax is already zero here
    mov dil, bl ; fd - Again safe because rdi never stores a number higher than 255
    mov dx, 65535 ; count - Safe because this is the highest number ever stored in rdx
    syscall
    mov [rsp+8], byte 48 ; Set syscall number in error string

    test eax, eax
    js short exit_print_error


write:
    ; write syscall
    xchg edx, eax ; amount of bytes read - Safe because rdx contains a number equal or lower than 65535
    mov ax, 1 ; sys_write - Safe because rax contains a number equal or lower than 65535
    mov dil, 1 ; stdout - Safe because only small number in rdi
    syscall

    test eax, eax
    js short exit ; No point trying to print an error message if the write call fails lol

    xor eax, eax ; sys_read

    sub r13, rdx
    jnz short read_loop

    xor edi, edi ; Set exit code to 0

exit:
    mov eax, 60 ; sys_exit
    syscall

exit_print_error:
    xchg ebx, eax ; save error code
    mov eax, 1 ; sys_write
    mov edi, 2 ; stderr
    mov dx, 17
    mov rsi, rsp
    syscall
    xchg edi, ebx ; set error code
    jmp short exit

estr: db `SYSCALL x failed\n`
end_of_code:

section .bss
buffer: resb 65535

end_of_bss:
