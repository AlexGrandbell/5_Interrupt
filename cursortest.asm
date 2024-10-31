code segment
start:  
mov ah, 01h      ; 功能号：设置光标形状
mov ch, 32h      ; 设置开始行号为 32，使光标不可见
mov cl, 32h      ; 设置结束行号为 32，使光标不可见
int 10h



mov ah, 02h        ; 功能号：设置光标位置
mov dh,25
mov dl,0
int 10h

lll:
mov ah, 03h      ; 功能号：获取光标位置和形状
mov bh, 0        ; 页号，通常为 0
int 10h


; 在光标位置输出字符
mov ah, 09h
mov al, ' '         ; 要输出的字符
mov bl, 0Fh         ; 黑底白字
mov bh,0 ;黑底白字
mov cx, 1           ; 重复显示次数
int 10h

mov ah, 02h        ; 功能号：设置光标位置
sub dh,1
add dl,3
int 10h

; 在光标位置输出字符
mov ah, 09h
mov al, 'A'         ; 要输出的字符
mov cx, 1           ; 重复显示次数
int 10h

call delay1

jmp lll

;延时
delay1:
    push ax
    push cx
    mov ax,0FFFFh ;更改该数字调整为1秒
    s1:
        sub ax,1
        mov cx,015h
        subloop:
            sub ax,0
        loop subloop
        cmp ax,0
    jne s1
    pop cx
    pop ax
ret
code ends
end start
