org  100h	; set location counter to 100h

print_str macro out_str
    mov ah,9
    mov dx, offset out_str
    int 21h
endm

enter_str macro str
    mov ah,0Ah
    lea dx, str
    int 21h   
endm

new_line macro
    mov ah, 02h    
    mov dl, 0Ah    
    int 21h        
    mov dl, 0Dh   
    int 21h
endm    
get_len macro str
  cld
  lea si, str
  xor cx, cx
  
  loop:
   lodsb
   cmp al, '$'
   jz done
   cmp al, 0Dh
   jz done
   inc cx
   jmp loop
  
  done:
   nop
endm    
isEmpty macro str
   cmp str[1],0
   je empty      
endm

start:  
    print_str msg1    
    enter_str str 
    isEmpty str 
    print_str msg2
    enter_str word
    isEmpty word
    print_str msg3
    enter_str new_word
    isEmpty new_word 
                     
    mov di, offset new_word + 2 
    xor bx,bx
    loop:
    cmp [di], '$'
    je notFound
    cmp [di], 0Dh
    je finish
    inc di
    inc bx
    jmp loop
    
    finish:
    push bx
    ;setting ax to the first char position
    mov ax, offset str + 2
    jmp find_first_char
                 
find_first_char: 
   ; load from dx next pos 
   mov di, ax    
   mov bx, offset word + 2 
   ; first symbol to compare
   mov ax, [bx] 
   jmp find  
       
find: 
   ; search for 1 symbol
   scasb  
   ; if found go next
   je next   
   ; if in word it was last symbol 
   cmp [di], '$'
   je notFound
   jmp find
       
next:   
   inc bx    
   ; save position to load it in 'one' step
   mov ax, di
   mov si, bx    
   ; if it end, go to 'after' step
   repe cmpsb   
   cmp [si], '$'
   je prepLen    
   jmp find_first_char  
      
notFound:
   print_str e404
   mov ah, 01h
   int 21h
   ret  
       
prepLen:   
   ; if word is last in str -> print str    
   cmp [di], '$'
   je print     
   ; count from 1 to include space symbol
   mov dx, 0
   pop bx  
   jmp getLen

;gettin len of the rest part of string       
getLen:      
   push [di] 
   inc di 
   inc dx
   ; if space symbol -> it is end of word
   cmp [di], '$'
   je move
   ; or it last word in str
   cmp [di], 0Dh
   je move     
   jmp getLen
       
move:
   push 0Dh
   dec ax
   ; set di to begin of str
   mov di, ax 
   xor dx, dx
   jmp replace
    
replace:
   mov cx, bx
   mov si, offset new_word +2
   repnz movsb
   mov [di], ' '
   inc di  
   mov sp, 0FFFCh
   loop_str:
    pop [di]
    inc di
    dec sp
    dec sp 
    dec sp
    dec sp
    cmp [di], 0
    je print
    jmp loop_str

print:   
    new_line
    print_str str+1        
    mov ah, 01h
    int 21h
    ret

empty:
    print_str empty_str
    ret
                  
msg1 db "Input string with words: $"   
msg2 db 0Dh, 0Ah, "Input word to replace: $"
msg3 db 0Dh, 0Ah, "Input new word: $"         
e404 db 0Dh, 0Ah, "NOT FOUND$"
empty_str db 0Dh, 0Ah, "EMPTY STRING"
str db 200 dup('$')  
word db 200 dup('$')
new_word db 200 dup<'$'>
