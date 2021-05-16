BITS 64
    org 0x08048000

; ELF64 Header
ehdr:
                db 0x7F, "ELF", 2, 1, 1, 0 ; e_ident[16]
    times 8     db 0 ;
                dw 2 ; e_type
                dw 62 ; e_machine
                dd 1 ; e_version
                dq _start; e_entry      /* Entry point virtual address */
                dq phdr - $$; e_phoff   /* Program header table file offset */
                dq 0 ; e_shoff          /* Section header table file offset */
                dd 0 ; e_flags
                dw ehdrsize ; e_ehsize
                dw phdrsize ; e_phentsize;
                dw 1 ; e_phnum;
                dw 0 ; e_shentsize;
                dw 0 ; e_shnum;
                dw 0 ; e_shstrndx;

ehdrsize equ $-ehdr ; 64 bytes


phdr:
                dd 1 ; p_type;
                dd 7 ; p_flags;
                dq 0 ; p_offset;                      /* Segment file offset */
                dq $$ ; p_vaddr;                      /* Segment virtual address */
                dq 0 ; p_paddr;                       /* Segment physical address */
                dq end_of_file-_start ; p_filesz      /* Segment size in file */
                dq end_of_file-_start ; p_memsz       /* Segment size in memory */
                dq 4096 ; p_align                     /* Segment alignment, file & memory */

phdrsize equ $-phdr ; 56




%macro check_error 2+
    j%-1 %%no_error
    mov rsi, %%str ; pointer
    mov rdx, %%no_error-%%str ; length
    jmp exit_print_error
    %%str: db  %2
    %%no_error:
%endmacro

_start:
    ; Check that there is exactly 1 command line argument.
    ; It's comparing against 2 because the first one is always the program itself
    mov rax, [rsp]
    cmp rax, 2
    check_error ne, `Usage: scat [filename]\n`

    ; Open file
    mov rdi, [rsp+16] ; file path
    syscall

    test rax, rax
    check_error s, `Can't open file!\n`

    mov r15, rax ; Save fd




    ; Memory for fstat call
    mov rax, 9 ; sys_mmap
    xor rdi, rdi ; addr
    mov rsi, 65535 ; size
    mov rdx, 1 | 2 ; PROT_READ | PROT_WRITE
    mov r10, 2 | 0x20 ; MAP_PRIVATE | MAP_ANONYMOUS
    syscall

    test rax, rax
    check_error s, `Can't allocate memory for fstat call!\n`

    mov r14, rax ; pointer to fstat struct

    ; Fstat call to get file size
    mov rsi, rax ; pointer
    mov rax, 5 ; sys_fstat
    mov rdi, r15 ; fd
    syscall

    test rax, rax
    check_error s, `fstat call failed!\n`


    mov r13, [r14+48] ; load file size

read_loop:

    xor rax, rax ; sys_read
    mov rdi, r15 ; fd
    mov rsi, r14 ; buffer pointer
    mov rdx, 65535 ; count
    syscall

    test rax, rax
    check_error s, `Can't read file\n`

    mov r12, rax

    ; write syscall
    mov rax, 1 ; sys_write
    mov rdi, 1 ; stdout
    mov rsi, r14 ; buffer pointer
    mov rdx, r12 ; count
    syscall

    test rax, rax
    js exit_error ; No point trying to print an error message if the write call fails lol

    sub r13, r12
    jnz read_loop

    ; Terminate program
    mov rax, 60 ; sys_exit
    xor rdi, rdi ; error code = 0
    syscall



exit_print_error:
    mov rax, 1 ; sys_write
    mov rdi, 2 ; stderr
    syscall

exit_error:
    ; Terminate program with error code
    mov rax, 60 ; sys_exit
    mov rdi, 1 ; error code = 1
    syscall

end_of_file:
    filesize equ $-$$
