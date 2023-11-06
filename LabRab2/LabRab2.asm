org  100h

print_str macro out_str
    mov ah,9
    mov dx,offset out_str
    int 21h
endm

get_str macro get_str
    mov ah,0Ah
    mov dx,offset get_str
    int 21h
endm 

new_line macro
    mov ah, 9
    mov dx, offset empty_line
    int 21h
endm 

;-----------------------------

start:
    mov bx,0
    print_str len_msg
    get_str buf_len
     
;reading entered len of array   
    mov si, offset buf_len + 2
    xor cx,cx
    mov cl, [buf_len+1]
    mov bx, 0
    mov dx, 0
    
    _input_loop:
    mov al,[si]
    sub al, '0'
    mov ah, 0
    xor ax,dx
    xor dx,ax
    xor ax,dx
    mov ten, 10
    imul ten
    add ax, dx
    mov dx, ax
    inc si
    dec cx 
    mov [buf_len + bx], al
    cmp cx,0
    je end_loop
    jne _input_loop
    
    end_loop:
    mov bl, buf_len
    xor ax,ax
    mov al, bl
    mov bl, 2
    imul bl
    mov buf_len, al
    xor ax,ax
    xor bx,bx
    new_line
    print_str msg
    jmp input_loop   
           
input_loop:
    push bx 
    call input
    pop bx
    lea di, array
    add di, bx
    stosw
    add bx,2
    cmp bl, buf_len
    jne input_loop

    call find_max_el
    pop bx ;recieving max element
    jmp division

;-----------------------------

input proc    
inp_start:
    get_str curr_num
    print_str probel
    
    mov bx, 10
    mov ax, 0
    lea si, curr_num + 2
    mov cl, curr_num + 1 ;len of str
    cmp cl, 0
    je err_not_a_num
    mov cl, [si]
    mov dl, 0
    push dx
    cmp cl,'-'
    jne num 
    ;if we have negative
    mov cl, curr_num + 1
    cmp cl, 1
    je err_not_a_num_dx
    pop dx
    mov dl,1
    push dx
    inc si
    jmp inp

err_not_a_num:
    print_str empty_line
    print_str not_a_num
    jmp inp_start

err_not_a_num_dx:
    pop dx
    print_str empty_line
    print_str not_a_num
    jmp inp_start
        
overflow_err:
    pop dx
    print_str empty_line
    print_str overflow
    jmp inp_start
    
inp: 
    mov cl, [si]
    cmp cl, '$'
    je end_input
    cmp cl, 13 ;cret symbol
    je end_input
    jmp num
    
num: ;adding digits to num
    cmp cl, '0' ;checking if it contains only digits
    jl err_not_a_num_dx
    cmp cl,'9'
    ja err_not_a_num_dx
    
    sub cl, '0'
    imul bx
    jo overflow_err
    mov ch,0
    test al,al
    add ax,cx
    jo overflow_err ;if we have overflow
    inc si
    jmp inp
  
is_negative:
    not ax
    add ax,1
    jmp end
    
end_input:
    pop dx
    cmp dl,1
    je is_negative
    jmp end
    
end:
    ret
input endp

;-----------------------------

find_max_el proc
    lea di, array
    lea si, array+2
    xor cx,cx
    mov bx, 0 ;contains max el
    sub buf_len, 2 ;temp
search_loop:
    mov ax, [si]
    mov bx, [di]
    cmp ax, bx
    jge update_max
    add cx,2
    cmp cl, buf_len  ;len !need to check this condition
    jge end_proc
    add si,2
    jmp search_loop
        
update_max:
    mov bx, ax
    mov di, si
    add si,2
    add cx,2
    jmp search_loop         

end_proc:
    push bx ;max el in stack
    add buf_len,2
    jmp division
            
find_max_el endp 
;----------------------------- 

division: 
    mov div_minus, 0
    mov num_minus, 0
    xor cx,cx
    mov cl, buf_len
    mov tmp_len, cl
    xor cx,cx
    mov cl, accuracy ;amount of signs
    lea si, array
    lea di, div_num_res
    cmp bx, 0
    je zero_division
    test bx,bx
    js negative_divisor 
    
division_loop:
    push bx
    
    lodsw  ;loading num in ax
    test ax,ax
    js negative_div

cont:
    push ax
    xor dx,dx
    div bx
    ;push dx 
;Stas
    pop ax
    push dx
    ;push ax
    push cx
    mov ten2, 0Ah
    mov cx, 0 
    xor dx,dx
    div bx
    lp1:
    xor dx, dx
    div ten2
    add dx, 30h
    push dx
    inc cx
    cmp ax, 0
    jne lp1
    lp2:
    pop dx
    mov [di], dx
    inc di
    loop lp2
    mov byte di, '.'
;endS    
    
next_step:
    pop cx
    pop ax
    imul ten2    
    mov byte di, ','
    inc di
    jmp div_loop
    
div_loop:
    xor dx,dx
    idiv bx 
    add al, '0'
    mov byte [di], al
    inc di
    mov ax, dx
    imul ten
    dec cx
    cmp cx,0
    jne div_loop
    je next_num
    
negative_div:
    sub ax,1
    not ax
    cmp div_minus, 0
    je add_minus
    jne cont      
     
add_minus:
    mov byte di, '-'
    inc di
    jmp cont 
    
next_num:
    mov num_minus, 0
    mov byte di, ' '
    inc di
    xor cx,cx
    mov cl, tmp_len
    sub cx,2
    cmp cx, 0
    je loop_end
    mov tmp_len, cl
    
    xor cx,cx 
    mov cl, accuracy
    jmp division_loop
    
negative_divisor:
    sub bx, 1
    not bx
    mov div_minus, 1 
    jmp division_loop 

zero_division:
    new_line
    print_str zero_div
    
    mov ah, 4Ch
    int 21h
    
loop_end:
    new_line
    print_str result
    print_str div_num_res
    
    mov ah, 4Ch
    int 21h  

;----------------------------- 
    array dw 30 dup (0)    
    buf_len db 6
    ten db 10  
    ten2 dw 0010
    accuracy equ 5
    tmp_len db 1
    div_minus db 0
    num_minus db 0
    
    len_msg db "Input array len : ", 0Dh, 0Ah, '$'     
    msg db "Enter array of integers (30 numbers) : ",0Dh, 0Ah, '$'
    result db "Array after normalization : ", 0Dh, 0Ah, '$'
    ending db "The end!!", 0Dh,0Ah,'$'
    empty_line db 0Dh,0Ah,'$'
    inf db "inf$"
    zero_div db "Ahtung! Division by zero", 0Dh, 0Ah, '$'   
    
    curr_num db 7,0,7 dup ('$')
    div_num_res db 40 dup ('$')          
    div_res dw 30 dup(0)
    probel db " $"     
    
    not_a_num db "Ahtung!Incorrect input. Not a number", 0Dh,0Ah, '$'
    overflow db "Ahtung!Overflow!Values must be in range -32767..32767", 0Dh,0Ah,'$'
;-----------------------------