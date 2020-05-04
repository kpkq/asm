cseg segment PARA PUBLIC 'code'
assume cs:cseg
start:
    push bp
    mov bp, sp

    mov ax, [ss:bp+8]
    mov bx, [ss:bp+6]

    sub ax, bx

    mov [ss:bp+10], ax
    pop bp
retf
cseg ends
end start