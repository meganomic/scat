bits 32
    org 0x00048000

; Elf32_Ehdr
    db 0x7f, 'ELF'  ; e_ident (the part that is validated)
    ;db 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; e_ident (the part no one cares about)
    dd 1                    ; p_type PT_LOAD
    dd 0                    ; p_offset
    dd $$                   ; p_vaddr

    dw 2         ; e_type ET_EXEC
    dw 3        ; e_machine EM_386

    ;dd 1        ; e_version EV_CURRENT
    dd _start     ; p_filesz

    ;dd _start   ; e_entry
    dd _start     ; p_memsz

    dd 4  ; e_phoff
    ;dd 1        ; e_shoff (ignored)
    ;dd 0        ; e_flags
    ;dw 52     ; e_ehsize
_start:
    pop ebx
    pop ebx
    pop ebx

    mov al, 5
    int 0x80 ; open

    xchg eax, ecx
    jmp short cont

    dw 32     ; e_phentsize
    dw 1  ; e_phnum
    ;dw 0  ; e_shentsize
    ;dw 0  ; e_shnum
    ;dw 0  ; e_shstrndx

; Elf32_Phdr
;phdr:
    ;dd 1                    ; p_type PT_LOAD
    ;dd 0                    ; p_offset
    ;dd $$                   ; p_vaddr

    ;dd 0                    ; p_paddr (ignored)

    ;dd end_of_code - $$     ; p_filesz

    ;dd end_of_code - $$     ; p_memsz

    ;dd 4                    ; p_flags PF_R
    ;dd 1                    ; p_align

cont:
    xchg eax, ebx
    xchg eax, ebp

    mov al, 187
    inc ebx
    not esi
    int 0x80 ; sendfile

    xchg eax, ebx
    int 0x80 ; exit

end_of_code:
