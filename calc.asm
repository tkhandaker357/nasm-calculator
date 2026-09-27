[bits 64]
default rel

; IT WORKS!!!
; division is uhhh odd though
; TODO: make work for floating point numbers

section .data
    operations      db "add","sub","mul","div"
    opsLen          db $-operations
    askForNum1      db "give a whole number: ",0
    askForNum2      db "give another number: ",0
    whatToDo        db "what do you want to do with them?", 10
                    db "write +, -, *, /, or", 10
                    db "write 'add', 'sub', 'mul', div': ",0
    addForOutput    db " + ",0
    subForOutput    db " - ",0
    mulForOutput    db " * ",0
    divForOutput    db " / ",0
    equForOutput    db " = ",0
    remForDiv       db ", r: ",0
    invalidInput    db "invalid input!",0


section .bss
    numBuffer resb 24
    strBuffer resb 8

section .text
    global _start

_start:
    push rbp
    mov rbp, rsp
    ; TWO NUMBERS TEST
    mov rax, askForNum1
    call printStr
    ; read first number into pre-allocated stack
    ; maximum size = 19 digits (64 bit integer limit), allocated 24 bytes for stack alignment 
    lea rax, numBuffer
    mov rdx, 24
    call readStr 
    ; convert to integer and place in stack space above area allocated for input
    sub rsp, 8
    call strToInt
    mov [rsp], rax

    mov rax, askForNum2
    call printStr
    ; replace bytes at string allocated for first number and read second number into pre-allocated stack space
    lea rax, numBuffer
    mov sil, 0
    mov dl, 10
    call replaceBytes
    mov rdx, 24
    call readStr
    ; convert second input to integer
    sub rsp, 8
    call strToInt
    mov [rsp], rax

    call printNewLine
    ; move onto calculation
    mov rax, whatToDo
    call printStr
    lea rax, strBuffer
    call readStr

    .cmpWithOps:
        push rax
        call printNewLine
        pop rax
        cmp byte [rax], 97
        jge .isAlpha
        cmp byte [rax], 42
        jge .isSymbol
        jmp .isInvalid
        .isSymbol:
            cmp byte [rax], '+'
            je .isAdd
            cmp byte [rax], '-'
            je .isSub
            cmp byte [rax], '*'
            je .isMul
            cmp byte [rax], '/'
            je .isDiv
            jmp .isInvalid
            
        .isAlpha:
            mov rcx, 0
            mov bl, byte [operations]
            cmp byte [rax], bl
            je .validateAdd
            mov bl, byte [operations + 3]
            cmp byte [rax], bl
            je .validateSub
            mov bl, byte [operations + 6]
            cmp byte [rax], bl
            je .validateMul
            mov bl, byte [operations + 9]
            cmp byte [rax], bl
            je .validateDiv
            jmp .isInvalid

            .validateAdd:
                cmp rcx, 3
                je .isAdd
                mov bl, byte [operations + rcx]
                cmp byte [rax + rcx], bl
                jne .isInvalid
                inc rcx
                jmp .validateAdd
            .validateSub:
                cmp rcx, 3
                je .isSub
                mov bl, byte [(operations + 3) + rcx]
                cmp byte [rax + rcx], bl
                jne .isInvalid
                inc rcx 
                jmp .validateSub
            .validateMul:
                cmp rcx, 3
                je .isMul
                mov bl, byte [(operations + 6) + rcx]
                cmp byte [rax + rcx], bl
                jne .isInvalid
                inc rcx
                jmp .validateMul
            .validateDiv: 
                cmp rcx, 3
                je .isDiv
                mov bl, byte [(operations + 9) + rcx]
                cmp byte [rax + rcx], bl
                jne .isInvalid
                inc rcx
                jmp .validateDiv

        .isAdd:
            mov rax, [rsp + 8]
            mov rbx, [rsp]
            push rax
            push rbx
            call intToStr
            call printStr
            pop rbx
            mov rax, addForOutput
            call printStr
            mov rax, rbx
            push rbx
            call intToStr
            pop rbx
            call printStr
            pop rax
            add rax, rbx
            mov r8, rax
            mov rax, equForOutput
            call printStr
            mov rax, r8
            call intToStr
            call printStr
            call printNewLine
            jmp _exit
        .isSub:
            mov rax, [rsp + 8]
            mov rbx, [rsp]
            push rax
            push rbx
            call intToStr
            call printStr
            pop rbx
            mov rax, subForOutput
            call printStr
            mov rax, rbx
            push rbx
            call intToStr
            pop rbx
            call printStr
            pop rax
            sub rax, rbx
            mov r8, rax
            mov rax, equForOutput
            call printStr
            mov rax, r8
            call intToStr
            call printStr
            call printNewLine
            jmp _exit
        .isMul:
            mov rax, [rsp + 8]
            mov rbx, [rsp]
            push rax
            push rbx
            call intToStr
            call printStr
            pop rbx
            mov rax, mulForOutput
            call printStr
            mov rax, rbx
            push rbx
            call intToStr
            pop rbx
            call printStr
            pop rax
            imul rax, rbx
            mov r8, rax
            mov rax, equForOutput
            call printStr
            mov rax, r8
            call intToStr
            call printStr
            call printNewLine
            jmp _exit
        .isDiv:
            ; need to do floating point bullshit for this to work :(
            mov rax, [rsp + 8]
            mov rbx, [rsp]
            push rax
            push rbx
            call intToStr
            call printStr
            pop rbx
            mov rax, divForOutput
            call printStr
            mov rax, rbx
            push rbx
            call intToStr
            pop rbx
            call printStr
            pop rax
            xor rdx, rdx
            idiv rbx
            push rdx
            mov r8, rax
            mov rax, equForOutput
            call printStr
            mov rax, r8
            call intToStr
            call printStr
            mov rax, remForDiv
            call printStr
            pop rdx
            mov rax, rdx
            call intToStr
            call printStr
            call printNewLine
            jmp _exit

        .isInvalid:
            mov rax, invalidInput
            mov rbx, 1
            call printStr
            jmp _exit
    
_exit:
    mov rsp, rbp
    pop rbp
    mov rax, 60
    mov rdi, 0
    syscall


; @param: 
;   rax = address of string
; @return:
;   rax = integer
strToInt:
    xor rsi, rsi
    xor rdi, rdi
    mov rcx, 0

    cmp byte [rax], '-'
    je .flagNegative
    jmp .convertToIntLoop

    .flagNegative:
        mov rdi, 1
        inc rcx

    .convertToIntLoop:
        mov dl, byte [rax + rcx]
        cmp dl, '0'
        jl .convertToIntEnd
        cmp dl, '9'
        jg .convertToIntEnd
        imul rsi, 10
        sub dl, '0'
        add rsi, rdx
        inc rcx
        jmp .convertToIntLoop
    .convertToIntEnd:
    
    cmp rdi, 1
    je .isNegative
    jmp .finished

    .isNegative:
        neg rsi

    .finished:
        mov rax, rsi
        ret

; @param
;   rax = integer
; @return:
;   rax = address of string in func's stack frame
intToStr:
    xor rdi, rdi
    xor r10, r10
    xor r9, r9
    xor r8, r8
    xor rdx, rdx
    xor rbx, rbx

    cmp rax, 0
    jl .isNegative
    jmp .countChars
    
    .isNegative:
        mov rdi, 1
        neg rax
        inc r9

    .countChars:
        push rax
        mov rcx, 10
        .countBytesLoop:
            xor rdx, rdx
            div rcx
            inc r9
            cmp rax, 0
            je .countCharsEnd
            jmp .countBytesLoop
    .countCharsEnd:
    inc r9
    pop rax

    push rcx
    
    mov rcx, 8
    cmp r9, 8
    jl .allocMem
    mov r8, 8
    .allocMem:
        push rax
        mov rax, r9
        mov rdx, 0
        div rcx
        cmp rdx, 0
        jne .addByte
        jmp .allocBytes
        .addByte:
            inc rax
        .allocBytes:
            imul rax, 8
            mov r8, rax
        pop rax
    pop rcx

    .allocateString:
        push rbp
        mov rbp, rsp
        sub rsp, r8
        mov r10, rbp

        mov byte [r10], 0
        dec r10

        .allocStrLoop:
            mov rdx, 0
            div rcx
            add dl, '0'
            mov byte [r10], dl
            cmp rax, 0
            je .allocStrEnd
            dec r10
            jmp .allocStrLoop
        .allocStrEnd:

        cmp rdi, 1
        jne .finished
        dec r10
        mov byte [r10], '-'

    .finished:
        lea rax, [r10]
        mov rdx, r8
        mov rsp, rbp
        pop rbp
        ret

; @param:
;   rax = data (usually a string) that must be counted
;   dl = byte telling function where to stop
; @return:
;   rax = amount of bytes contained in data (overrides input)
countLen: 
    mov rcx, 0 

    .countBytesLoop:
        cmp byte [rax + rcx], dl
        je .countBytesEnd
        inc rcx
        jmp .countBytesLoop
    .countBytesEnd:

    mov rax, rcx
    ret

; @param:
;   rax = starting address of data
;   dl = last byte to replace
;   sil = what byte to replace the data with
; @return:
;   nothing, modifies value in rax
replaceBytes:
    mov rcx, 0

    .moveBytesLoop:
        cmp byte [rax + rcx], dl
        je .moveBytesLoopEnd
        mov byte [rax + rcx], sil
        inc rcx
        jmp .moveBytesLoop
    .moveBytesLoopEnd:
    mov byte [rax + rcx], sil
    ret


; @param:
;   rax = address of string
;   rbx = newline flag  
; @return: nothing
printStr:
    ; copying the string into printStr's stack frame requires me to count the characters in input
    ; whole reason i want to call countLen is to avoid that so ill just go back to making this a leaf func
    mov rdx, 0
    .countLenLoop:
        cmp byte [rax + rdx], 0
        je .print
        inc rdx
        jmp .countLenLoop

    .print:
        push rax
        mov rsi, rax
        mov rax, 1
        mov rdi, 1
        syscall
        pop rax

    cmp rbx, 1
    jne .finished
    mov rbx, rax
    call printNewLine
    mov rax, rbx

    .finished:
        ret

printChar:
    mov sil, al
    push rax
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall
    pop rax
    ret
    

printNewLine:
    mov rax, 1
    mov rdi, 1
    mov rdx, 1

    push rbp
    mov rbp, rsp
    
    sub rsp, 8
    mov byte [rbp - 8], 10
    lea rsi, [rbp - 8]
    syscall

    mov rsp, rbp
    pop rbp
    ret

; @param:
;   rax = address of the input numBuffer
;   rdx = size of input numBuffer
; @return:
;   rax = modified numBuffer (rax's address remains unchanged throughout--rax's value is modified) 
readStr:
    mov rsi, rax
    mov rax, 0
    mov rdi, 0
    syscall
    
    mov rcx, 0
    .validateInputLoop:
        cmp rcx, rdx
        je .notAStr
        cmp byte [rsi + rcx], 32
        jl .notAStr
        cmp byte [rsi + rcx], 126
        jg .notAStr
        inc rcx
        jmp .validateInputLoop
        .notAStr:
            mov byte [rsi + rcx], 10
            jmp .finished

    .finished:
    mov rax, rsi
    ret
