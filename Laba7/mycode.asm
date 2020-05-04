.model small
.stack 100h     
oseg segment
    retf
oseg ends
.data                          
  overlay_addr dw 0, 0
  overlay_epb dw 0, 0
  addname db 'add.exe', 0
  subname db 'sub.exe', 0
  mulname db 'mul.exe', 0
  divname db 'div.exe', 0
  error db 'error$' 
  minus db '-$'
  newl db ' $'
  leftNum dw 0
  rightNum dw 0
  result dw 0 
  fileName db 120 dup(0)
  border db 0
  args db 120 dup('$')
  
  bufferNum db 6 dup('$')
  operator db ' '
  symbol db 0
  fileid dw 0
  isEnded db 0
  isNewl db 0
  sign db 0
  signArray db 250 dup(?)
  numArray dw 250 dup(?)
  arrayOffset dw 0
.code

loadOverlay proc
    mov ax, oseg  
    mov [overlay_epb], ax 
    mov [overlay_epb + 2], ax

    mov bx, offset overlay_epb
    mov ax, 4B03h
    int 21h 
    mov ax, oseg   
    mov [overlay_addr + 2], ax
    push 0
    push leftNum
    push rightNum 
    call DWORD PTR overlay_addr
    pop ax
    pop ax      
    pop result     
    ret
loadOverlay endp

readSymbol proc 
    pusha
    mov dx, offset symbol
    mov bx, fileid
    mov cx, 1
    mov ah, 3Fh
    int 21h
    cmp ax, 0
    je fileEnded
    cmp symbol, 0Dh
    je fileEnded
    jne readSymbolFinish
fileEnded:
    mov isEnded, 1
    popa
    ret
readSymbolFinish:
    popa
    ret    
readSymbol endp

readStringFromFile proc
    mov di, offset bufferNum
    mov si, offset signArray 
    xor bx, bx
continueRead:    
    call readSymbol
    cmp isEnded, 1
    je newLine    
    cmp symbol, '+'
    je addSign
    cmp symbol, '-'
    je addSign
    cmp symbol, '*'
    je addSign
    cmp symbol, '/'
    je addSign
    cmp symbol, '0'
    jb readError
    cmp symbol, '9'
    ja readError
    jmp addSymbol
addSymbol:
    xor ah, ah
    mov al, symbol
    stosb 
    jmp continueRead 
addSign:
    call str2num
    push si
    mov si, offset numArray
    add si, arrayOffset
    mov [si], cx 
    pop si
    add arrayOffset, 2
    mov al, symbol
    mov [si], al 
    inc bl
    inc si
    mov di, offset bufferNum
    jmp continueRead    
readError:    
    
newLine:
    call str2num
    mov si, offset numArray
    add si, arrayOffset
    mov [si], cx
    ret    
        
readStringFromFile endp
    
 
str2num proc
    push si
    push bx
    mov bx, 10
    xor ax, ax
    xor cx, cx
    mov si, offset bufferNum
str2numP:    
    lodsb
    mov [si-1], '$'
    cmp al, '$'
    je str2numEnded
    sub al, '0'
    xchg ax, cx
    mul bx
    jo str2numError
    add ax, cx
    xchg ax, cx
    jmp str2numP
str2numEnded:
    pop bx
    pop si 
    ret
str2numError:
    printStr error
    mov ax, 4C00h
    int 21h    
str2num endp     

highPriorCalc proc
    mov border, 250
    mov si, offset signArray
    xor cx, cx
highPriorBegin:    
    lodsb
    cmp al, '*'
    je mulCalc
    cmp al, '/'
    je divCalc
    cmp al, 0
    je highPriorEnded
    inc cx
    cmp cl, border
    je highPriorEnded
    jmp highPriorBegin
    
mulCalc:
    mov bx, offset mulname
    jmp HPcalculation
divCalc:
    mov bx, offset divname
    jmp HPcalculation

HPcalculation:        
    mov di, offset numArray
    add di, cx
    add di, cx
    mov dx, [di]
    mov leftNum, dx
    add di, 2
    mov dx, [di]
    mov rightNum, dx
    mov dx, bx
    call loadOverlay
    mov ax, result
    stosw
    sub di, 2
    call delElement
    jmp highPriorBegin
highPriorEnded:
    ret    
highPriorCalc endp    

lowPriorCalc proc
    mov si, offset signArray
    xor cx, cx
lowPriorBegin:    
    lodsb
    cmp al, '+'
    je addCalc
    cmp al, '-'
    je subCalc
    cmp al, 0
    je lowPriorEnded
    inc cx
    cmp cl, border
    je lowPriorEnded
    jmp lowPriorBegin
    
addCalc:
    mov bx, offset addname
    jmp LPcalculation
subCalc:
    mov bx, offset subname
    jmp LPcalculation

LPcalculation:        
    mov di, offset numArray
    add di, cx
    add di, cx
    mov dx, [di]
    mov leftNum, dx
    add di, 2
    mov dx, [di]
    mov rightNum, dx
    mov dx, bx
    call loadOverlay
    mov ax, result
    stosw
    sub di, 2
    call delElement
    jmp lowPriorBegin
lowPriorEnded:
    ret    
lowPriorCalc endp

delElement proc
    push cx
    push di
    push si
    
    mov si, offset signArray
    mov di, offset signArray
    inc si
    add si, cx
    add di, cx
    mov dx, 250
    sub dx, cx
    sub dx, 2
    push dx
signDel:    
    lodsb
    stosb
    dec dx
    cmp dx, 0
    jne signDel
    
    pop dx
    mov si, offset numArray
    mov di, offset numArray
    add si, 2
    add si, cx
    add si, cx
    add di, cx
    add di, cx
numDel:
    lodsw
    stosw
    dec dx
    cmp dx, 0
    jne numDel    
    
    dec border
    pop si
    pop di
    pop cx 
    dec si
    ret
delElement endp    
printStr macro outStr
    mov ah, 09h
    mov dx, offset outStr
    int 21h
    endm 
showNum proc
    pusha
    mov bx, 10
    xor cx, cx
    cmp ah, 7Fh
    jbe begin 
    push ax
    printStr minus
    pop ax
    neg ax    
begin:
    xor dx, dx    
    div bx
    add dl, '0'
    push dx
    inc cx
    cmp ax, 0000
    jne begin
outLoop:
    pop dx
    mov ah, 02
    mov al, dl
    int 21h
    loop outLoop    
    popa
    ret
showNum endp

processingCmd proc
    mov di, offset fileName
    mov si, offset args
processingArgsFilename:    
    cmp [si], 0Dh
    je processingEnded
    movsb
    jmp processingArgsFilename    
processingEnded:
    ret
processingCmd endp    
            
main:       
    mov ax, @data
    mov es, ax    
    xor cx, cx
	mov cl, ds:[80h]			
	mov si, 82h
	mov di, offset args 
	rep movsb
	mov ds, ax
	call processingCmd           
    mov ax, 3D00h
    mov dx, offset fileName
    int 21h
    jc fileError    
    mov fileid, ax 

    call readStringFromFile
    call highPriorCalc
    call lowPriorCalc
    mov si, offset numArray
    lodsw
    call showNum    
    mov ax, 4C00h
    int 21h
fileError:
    printStr error
    mov ax, 4C00h
    int 21h    
end main   