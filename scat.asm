BITS 64
default rel
    org 0x08048000

; ELF64 Header
ehdr:
                db 0x7F, "ELF", 2, 1, 1, 0 ; e_ident[16]
                dq 0 ;
                dw 2 ; e_type
                dw 62 ; e_machine
                dd 1 ; e_version
                dq _start; e_entry      /* Entry point virtual address */
                dq phdr - $$; e_phoff   /* Program header table file offset */
                dq 0 ; e_shoff          /* Section header table file offset */
                dd 0 ; e_flags
                dw 64 ; e_ehsize
                dw 56 ; e_phentsize;
                dw 1 ; e_phnum;
                dw 0 ; e_shentsize;
                db 0
                ;dw 0 ; e_shnum;
                ;dw 0 ; e_shstrndx;

;ehdrsize equ $-ehdr ; 64 bytes


phdr:
                dd 1 ; p_type;
                dd 5 ; p_flags;
                dq 0 ; p_offset;                      /* Segment file offset */
                dq $$ ; p_vaddr;                      /* Segment virtual address */
                dq 0 ; p_paddr;                       /* Segment physical address */
                dq end_of_file-_start ; p_filesz      /* Segment size in file */
                dq end_of_file-_start ; p_memsz       /* Segment size in memory */
                dq 4096 ; p_align                     /* Segment alignment, file & memory */

;phdrsize equ $-phdr ; 56




%macro check_error 2+
    j%-1 short %%no_error
    mov rsi, %%str ; pointer
    mov dx, %%no_error-%%str ; length
    jmp exit_print_error
    %%str: db  %2
    %%no_error:
%endmacro

_start:
    ; Check that there is exactly 1 command line argument.
    ; It's comparing against 2 because the first one is always the program itself
    mov rax, [rsp]
    cmp al, 2
    check_error ne, `Usage: scat [filename]\n`

    ; Open file
    mov rdi, [rsp+16] ; file path
    syscall

    test eax, eax
    check_error s, `Can't open file!\n`

    mov bl, al ; Save fd - fd won't be above 255. I'll eat my shoes if it is


    ; Allocate some memory
    mov al, 9 ; sys_mmap - This is safe because al only has fd in it, which is small
    xor rdi, rdi ; addr
    mov si, 65535 ; size - This is safe because rsi is zero
    mov dl, 1 | 2 ; PROT_READ | PROT_WRITE - This is safe because rdi is zero
    mov r10b, 2 | 0x20 ; MAP_PRIVATE | MAP_ANONYMOUS - This is safe because r10 is zero
    syscall

    test eax, eax
    check_error s, `Can't allocate memory!\n`

    ; Fstat call to get file size
    mov rsi, rax ; pointer
    mov eax, 5 ; sys_fstat
    mov edi, ebx ; fd - This is safe because rdi is zero
    syscall

    test eax, eax
    check_error s, `fstat call failed!\n`

    mov r13, [rsi+48] ; load file size


read_loop:
    xor eax, eax ; sys_read
    mov dil, bl ; fd - Again safe because rdi never stores a number higher than 255
    mov dx, 65535 ; count - Safe because this is the highest number ever stored in rdx
    syscall

    test eax, eax
    check_error s, `Can't read file\n`

    ; write syscall
    mov dx, ax ; amount of bytes read - Safe because rdx contains a number equal or lower than 65535
    mov ax, 1 ; sys_write - Safe because rax contains a number equal or lower than 65535
    mov dil, 1 ; stdout - Safe because only small number in rdi
    syscall

    test eax, eax
    js short exit ; No point trying to print an error message if the write call fails lol

    sub r13, rdx
    jnz short read_loop

    xor rdi, rdi ; Set exit code to 0
exit:
    mov eax, 60 ; sys_exit
    syscall

exit_print_error:
    mov eax, 1 ; sys_write
    mov edi, 2 ; stderr
    syscall
    dec edi ; Set exit code to 1
    jmp short exit


end_of_file:
