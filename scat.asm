BITS 64
default rel
    org 0x08048000 ; default virtual address

; ELF64 Header
ehdr:
                db 0x7F, "ELF", 2, 1, 1;, 0 ; e_ident[16]
                ;dq 0 ;
_start:
    mov eax, [rsp]
    cmp al, 2
    je short open_file
    jmp short perr
                ;db 0 ; Filler byte
                dw 2 ; e_type
                dw 62 ; e_machine
                dd 1 ; e_version
                dq _start; e_entry      /* Entry point virtual address */
                dq phdr - $$; e_phoff   /* Program header table file offset */
                dq 0 ; e_shoff          /* Section header table file offset */
                dd 0 ; e_flags
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
                lea esi, str1
                jmp short err
                ;dq 0 ; p_paddr;                       /* Segment physical address */
                dq end_of_code-$$ ; p_filesz          /* Segment size in file */
                dq end_of_bss-$$ ; p_memsz               /* Segment size in memory */
                dq 4096 ; p_align                     /* Segment alignment, file & memory */



    ; Check that there is exactly 1 command line argument.
    ; It's comparing against 2 because the first one is always the program itself
    ;mov eax, [rsp]
    ;cmp al, 2
    ;je short open_file
    ;lea esi, str1
err:
    mov dl, 23
    jmp short jmp_indirect_exit
    str1: db `Usage: scat [filename]\n`


open_file:
    ; rax is already 2 here. 2 == sys_
    mov rdi, [rsp+16] ; file path
    syscall

    test eax, eax
    jns short fstat
    lea esi, str2
    mov dl, 17
    jmp short jmp_indirect_exit
    str2: db `Can't open file!\n`

fstat:
    mov bl, al ; Save fd - fd won't be above 255. I'll eat my shoes if it is

    ; Fstat call to get file size
    lea esi, buffer
    mov al, 5 ; sys_fstat
    mov edi, ebx ; fd - This is safe because it resets upper bits
    syscall

    test eax, eax
    jns short no_error
    lea esi, str3
    mov dl, 20
    jmp_indirect_exit: jmp short exit_print_error
    str3: db `Can't get filesize!\n`

no_error:
    mov r13, [rsi+48] ; load file size


read_loop:
    ; rax is already zero here
    mov dil, bl ; fd - Again safe because rdi never stores a number higher than 255
    mov dx, 65535 ; count - Safe because this is the highest number ever stored in rdx
    syscall

    test eax, eax
    jns short write
    lea esi, str4
    mov dx, 17
    jmp short exit_print_error
    str4: db `Can't read file!\n`


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
    syscall
    xchg edi, ebx ; set error code
    jmp short exit

end_of_code:

section .bss
buffer: resb 65535

end_of_bss:
