assume ds:data,ss:stack

data segment
    storeint9 dw 16 dup(0) ;存放int9中断的数据
    tipMsg db 'Please input a char: $' ;提示。应该用不了中文
    timeMsg db 0,2,4,7,8,9 ;存放CMOS对时间的接口
    symMsg db '/','/',' ',':',':',' ' ;存放时间间隔的接口
    userChar db 'A'
    charState db 1 ;字符在往上还是往下，1-上，0-下
data ends

stack segment
    dw 64 dup(0)
stack ends

code segment
start:
    ;设置数据段
    mov ax,data
    mov ds,ax
    ;设置栈段
    mov ax,stack
    mov ss,ax
    mov sp,64
    ;设置中断向量表段地址
    mov ax,0
    mov es,ax
    ;输出提示
    mov dx, offset tipMsg
    mov ah,09h
    int 21h
    ;获取输入
    mov ah,01h
    int 21h
    mov [userChar],al
    ;暂停一下，防止输入中断被后续直接捕获结束
    call delay0

    ;保存原int9地址的四个字节
    push es:[9*4]
    pop ds:[0]
    push es:[9*4+2]
    pop ds:[2]
    ;设置新的int9中断地址
    mov word ptr es:[9*4], offset newint9 ;设置中断地址偏移地址
    mov es:[9*4+2],cs ;设置中断地址段地址，也就是cs

    ;使光标不可见
    mov ah, 01h
    mov ch, 32h
    mov cl, 32h
    int 10h
    
    ;清屏
    call clearscreen

    ;设置光标位置
    mov ah, 02h
    mov dh,24
    mov bh,0
    mov dl,4
    int 10h

;进入死循环
clockloop:
    ;1时钟与动画
        mov bx,6
        mov si,0
        ;循环读取CMOS时间数据
        timeinputloop:
            mov al,timeMsg[si]
            out 70h,al
            in al,71h
            mov ah,al
            mov cl,4
            shr ah,cl
            and al,00001111b
            add ah,30H
            add al,30H
            push ax

            inc si
            sub bx,1
            cmp bx,0
        jne timeinputloop

        ;写入屏幕
        mov bx,0b800h
        mov es,bx
        mov di,160*12+32*2

        ;年份的20要自己补上
        mov byte ptr es:[di-4],032h
        mov byte ptr es:[di-2],030h

        mov cx,6
        mov si,0
        ;循环构造时间
        timeoutloop:
            pop ax
            mov byte ptr es:[di],ah
            mov byte ptr es:[di+2],al
            mov al,symMsg[si]
            mov byte ptr es:[di+4],al
            inc si
            add di,6
        loop timeoutloop

    ;2字符跳动
        ;获取光标位置,dh行dl列
        mov ah, 03h
        mov bh, 0
        int 10h

        ;清空当前位置的字符
        mov ah, 09h
        mov al, ' '
        mov bh,0
        mov bl,0fh
        mov cx, 1
        int 10h

        mov al,[charState]
        cmp al,0
        jne uping

        ;如果正在往下，则继续尝试往下
        downing:
            mov [charState],0;继续保持往下
            ;判断是否到底
            cmp dh,24
            je uping
            ;没到底则更改光标位置
            mov ah, 02h
            add dh,1
            sub dl,3
            int 10h
        jmp exit1

        ;如果正在往上，则继续尝试往上
        uping:
            mov [charState],1;继续保持往上
            ;判断是否到顶
            cmp dh,0
            je downing
            ;没到顶则更改光标位置
            mov ah, 02h
            sub dh,1
            add dl,3
            int 10h
        exit1:

        ;写入字符
        mov ah, 09h
        mov al, [userChar]
        mov bh,0
        mov bl,0fh
        mov cx, 1
        int 10h
    ;停顿一秒
    call delay1
jmp clockloop

;按下后程序
newint9:
    call clearscreen
    ;设置光标位置
    mov ah, 02h
    mov dh,24
    mov bh,0
    mov dl,4
    int 10h
    ;恢复光标
    mov ah, 01h
    mov ch, 6
    mov cl, 7
    int 10h
    ;恢复中断向量表
    mov ax,0
    mov es,ax
    mov ax,data
    mov ds,ax
    push ds:[0]
    pop es:[9*4]
    push ds:[2]
    pop es:[9*4+2]
    ;结束
    mov ax,4c00h
    int 21h

;延时
delay1:
    mov ax,0FFFFh
    s1:
        sub ax,1
        cmp ax,0
    jne s1
ret

;一次延时
delay0:
    mov ax,0FFFFh
    s2:
        sub ax,1
        mov cx,07h
        subloop2:
            sub ax,0
        loop subloop2
        cmp ax,0
    jne s2
ret

;清屏
clearscreen:
    ;清屏
    mov bx,0b800h
    mov es,bx
    mov di,0
    mov cx,07f0h ;一个屏幕要清空的字节数量
    emptyloop:
        mov byte ptr es:[di],0
        mov byte ptr es:[di+1],0fh ;黑底白字
        add di,2
    loop emptyloop
ret

code ends
end start