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
    pop rax
    cmp al, 2 ; 2 bytes
    je short openfile ; 2 bytes
    jmp short perr ; 2 bytes

                db 0 ; filler byte
                dw 2 ; e_type
                dw 62 ; e_machine
                dd 1 ; e_version
                dq _start; e_entry      /* Entry point virtual address */
                dq phdr - $$; e_phoff   /* Program header table file offset */
openfile:
    ; Load the pointer to the 1st 'real' argument aka the filepath into rdi and open it
    ; rax is already 2 here which is sys_open
    pop rdi ; 1 byte
    pop rdi ; 1 byte - pointer to the path to the file to open
    syscall ; 2 bytes
    test eax, eax ; 2 bytes
    push estr
    jmp short openfile_continue ; 2 bytes

                db 0 ; filler byter
                ;dd 0
                ;dq 0 ; e_shoff          /* Section header table file offset */
                ;dd 0 ; e_flags
                ;db 0
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
perr:
    ; Load the 'usage' error message pointer
    push str1 ; 5 bytes
    jmp short exit ; 2 bytes

                db 0 ; filler byte
                ;dq 0 ; p_paddr;                       /* Segment physical address */
                dq end_of_code-$$ ; p_filesz          /* Segment size in file */
                dq end_of_bss-$$ ; p_memsz               /* Segment size in memory */
                dq 4096 ; p_align                     /* Segment alignment, file & memory */


openfile_continue:
    ; Put address to error string in rsp
    ;mov esp, estr
    ;push estr

    mov cl, 50 ; Set syscall number for error string

    js short exit


fstat:
    xchg ebx, eax ; Save fd - fd won't be above 255. I'll eat my shoes if it is

    ; Fstat call to get file size
    mov esi, buffer
    mov al, 5 ; sys_fstat
    mov edi, ebx ; fd - This is safe because it resets upper bits
    syscall

    mov cl, 53 ; Set syscall number for error string

    test eax, eax
    js short exit

    mov r13, [rsi+48] ; load file size


read_loop:
    ; rax is already zero here which is sys_read
    mov dil, bl ; fd - Again safe because rdi never stores a number higher than 255
    mov dx, 65535 ; count - Safe because this is the highest number ever stored in rdx
    syscall

    mov cl, 48 ; Set syscall number for error string

    test eax, eax
    js short exit


write:
    ; write syscall
    xchg edx, eax ; amount of bytes read - Safe because rdx contains a number equal or lower than 65535
    mov ax, 1 ; sys_write - Safe because rax contains a number equal or lower than 65535
    mov dil, 1 ; stdout - Safe because only small number in rdi
    syscall

    test eax, eax
    js short exit

    xor eax, eax ; sys_read

    sub r13, rdx
    jnz short read_loop


exit:
    xchg ebx, eax ; save error code
    mov eax, 1 ; sys_write
    mov edi, 2 ; stderr
    mov dx, 16 ; length of string
    pop rsi ; error string pointer
    mov [rsi+8], cl
    jns short no_print ; Don't print an error message if there were no errors
    syscall

no_print:
    ; The exit code will always be nonzero even if there are no errors
    mov edi, ebx ; set error code
    mov al, 60 ; sys_exit
    syscall

    ; Some strings
    estr: db `SYSCALL x error\n`
    str1: db `scat [filename]\n`

end_of_code:

section .bss
buffer: resb 65535

end_of_bss:
