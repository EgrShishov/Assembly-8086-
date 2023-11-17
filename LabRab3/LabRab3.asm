org 100h
 
print macro str
    mov ah, 09h
    lea dx, str
    int 21h    
endm

get_str macro str
    mov ah, 0Ah
    lea dx, str
    int 21h    
endm

newline macro
    mov ah, 02h    
	mov dl, 0Ah    
	int 21h   	 
	mov dl, 0Dh   
	int 21h  
endm

;--------------------------- 
  
start:
    xor cx,cx 
    mov cl,[80h] 
    xor ax,ax
    mov al,cl
    mov si, 81h
    lea di, args
    
    xor ax,ax
    cld
get_args:
    lodsb
    cmp al,0Dh
    je have_args
    stosb
    jmp get_args
    
have_args:    
    mov al,0
    stosb
    
;params parser
    xor cx,cx
    lea si, args+1
    lea di, fname
parse_fn:
    lodsb
    cmp al,32
    je fn_end
    cmp al,09
    je fn_end
    cmp al,0
    je err_params1 ;not enought params
    stosb
    inc cx
    cmp cx,100
    je err_params2 ;file name is too long
    jmp parse_fn        

fn_end:    
    mov al,0
    stosb
    mov al,'$'
    stosb
    
    mov dx, offset fname
    print fname_msg
    print fname
    call fopen
    call success
    jmp reading

reading:    
    xor dx,dx    
    jmp processing
    
f_close:
    call fclose
    jmp end_program 

;---------------------------
;finding loop

processing:
    lea di, word
    mov cx,0
    
parse_word:
    lodsb
    cmp al,' '
    je word_end
    cmp al, 09
    je word_end
    cmp al, 0
    je word_end
    
    stosb
    inc cx
    cmp cx,100
    je too_big_word_err
    jmp parse_word
    
word_end:
    mov al, 0
    stosb
    mov al, '$'
    stosb
    
    newline
    print word_msg
    print word
    
    jmp file_processing

file_processing:
    call line_to_buff
    inc linecount
    call find_word_in_line
    cmp EOF, 0
    je file_processing
    jne end_program 
        
;---------------------------  
;error handlers

err_not_found:
    print err_msg1
    newline
    jmp end_program
    
err_path_not_found:
    print err_msg2
    newline
    jmp end_program
    
err_too_many_open_files:
    print err_msg3
    newline
    jmp end_program
    
err_access_denied:
    print err_msg4
    newline
    jmp end_program

err_wrond_mode:
    print err_msg5
    newline
    jmp end_program        

err_params1:
    print err_1
    newline
    jmp end_program
    
err_params2:
    print err_2
    newline
    jmp end_program
    
too_big_word_err:
    print err_3
    newline
    jmp end_program  
        
end_program:       
    mov ah, 09h
    mov dx, offset res_msg
    int 21h
    call to_string
    mov ah, 09h
    mov dx, offset ans_str
    int 21h
    ret

fopen proc near
    mov cx, 0
    mov ah, 3Dh
    mov al, 0 ; for reading
    int 21h 
    jc err
    jmp fdesc
    
err:
    cmp ax, 02h
    je err_not_found
    cmp ax, 03h
    je err_path_not_found
    cmp ax, 04h
    je err_too_many_open_files
    cmp ax, 05h
    je err_access_denied
    cmp ax, 0Ch
    je err_wrond_mode

fdesc:   
    mov bx,ax
    ret
endp    

fclose proc 
    mov ah, 3Eh
    int 21h
    ret
endp

success proc 
    print suc_msg1
    newline
    ret
success endp

line_to_buff proc 
    push ax
    push cx
    push si
    push di
    
    lea dx, buf
casting:
    mov ah, 3Fh
    mov cx,1
    int 21h
    mov di, dx
    cmp [di], 10  ;\n
    je casting
    cmp [di], 13  ;\r
    je endline
    cmp ax, 0
    je endfile
    inc dx                               
    jmp casting
    
endline:
    dec dx
    mov al, 0 ;change to zero
    inc dx
    mov di,dx
    mov [di], al
    inc dx
    mov al, '$'
    mov di, dx
    mov [di], al
    mov EOF, 0
    jmp endproc
    
endfile:
    dec dx
    mov al, 0  ;change to zero
    inc dx
    mov di, dx
    mov [di], al
    inc dx
    mov al, '$'
    mov di, dx
    mov [di], al
    mov EOF, 1
    jmp endproc
    
endproc:
    pop di
    pop si
    pop cx
    pop ax
    ret    
               
line_to_buff endp
    
find_word_in_line proc     
    push ax
    push bx
    push cx
    push di
    push si
    
    xor cx,cx 
    ;lea si, word ; loading word and cur line in memory
    ;lea di, buf

    mov ax, offset buf
    jmp find_first_char
  	 
find_first_char:
   ; load from dx next pos
   mov di, ax    
   mov bx, offset word
   ; first symbol to compare
   mov ax, [bx]
   jmp find  
  	 
find:
   ; search for 1 symbol
   scasb  
   ; if found go next
   je next   
   ; if in word it was last symbol
   cmp [di], 0Dh
   je end_finding_proc
   cmp [di], 0
   je end_finding_proc
   jmp find
  	 
next:   
   inc bx    
   ; save position to load it in 'one' step
   mov ax, di
   mov si, bx    
   ; if it end, go to 'after' step
   lp:
   cmp [di], 0
   je next_check
   cmpsb
   je lp                                    
   
   dec di
   dec si
   cmp [di], ' '
   je next_check
   cmp [di], 0
   je next_check   

find_space:
   lp2:
   inc di
   cmp [di], 0
   je end_finding_proc
   cmp [di],' '
   jne lp2
   je prep

prep:
   mov bx, offset word
   mov ax, [bx]
   jmp find     
       
next_check:   
   cmp [si], 0
   je is_founded
   je end_finding_proc
   jne find_space

is_founded:
   mov ax, ans
   inc ax
   mov ans, ax
   jmp end_finding_proc 
        
end_finding_proc:
    pop si
    pop si
    pop cx
    pop bx
    pop ax
    ret            
find_word_in_line endp

;--------------------------- 

to_string proc
    push ax
    push bx
    push cx
    push dx
    push di
    
    xor cx,cx
    mov bx,10
   ;mov ans, 16
    mov ax, ans
    lea di, ans_str

conv_loop:
    xor dx,dx
    div bx
    push dx
    inc cx
    test ax,ax
    jnz conv_loop

to_str:
    pop dx
    add dl, '0'
    mov [di], dl
    inc di
    dec cx
    cmp cx, 0
    je end_conv
    jmp to_str     
    
end_conv:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
        
to_string endp

;--------------------------- 
argc dw 0 ;amount of params
args db 130 dub(0) ;params
path db 30 dup('$')
filename db 'c:\len.txt', 0
fname db dup(0), 0
word db 55 dup(0)
buf db 2048 dup(0)
EOF dw 0
linecount dw 0
ans dw 0
ans_str db 30 dup('$')

fname_msg db "Entered filename -> ", '$', 0Dh, 0Ah
res_msg db "Amount of lines with given word -> ", '$', 0Dh, 0Ah
word_msg db 'Entered word : ', '$', 0Dh, 0Ah
noFileErr db "Achtung!There are no file with such name", 0Dh, 0Ah, '$'
noDataErr db "Achtung!No data in file!", 0Dh, 0Ah, '$'

err_msg1 db "Achtung!FOPEN: File not found!", '$' 
err_msg2 db "Achtung!FOPEN: Path not found!", '$'
err_msg3 db "Achtung!FOPEN: Too many files are opened!", '$'
err_msg4 db "Achtung!FOPEN: Access denied!", '$'
err_msg5 db "Achtung!FOPEN: Wrong access mode!", '$' 
err_cant_find_word db "Achting!Can not find the given word in the file", '$', 0Dh, 0Ah

err_1 db "Achtung!Not enough parametrs", '$' 
err_2 db "Achtung!Filename is too long", '$'
err_3 db "Achtung! Word is too long(maximum 50 symbols)"

suc_msg1 db "FOPEN: Success!", '$'
suc_msg2 db "FCLOSE: Success!", '$'

;---------------------------
end start
ret