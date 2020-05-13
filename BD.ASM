	.model small
	.stack 100h

 	.data
inp_name    db 'data.txt',0 		; name of the file that we encrypt
errmsg      db 'error$'     
descr       dw ?            		; file descriptor     
buf         db 256 dup(?)   		; buffer for the numbers we read 
num_read    dw ?            		; place to keep the size of the read numbers 
cword       db 'ROSKO'     		    ; keyword for virjener's cypher
keylen      equ $-cword    		    ; size of the the key for virjener's cypeher
cmask       equ 01001010b   		; mask for senc (simple encode)
cofs        equ 47          		; offset for senc(simple encode)
scbcmask    equ 01010010b   		; mask for cbc
sofs        equ 7 					; offset for cbc 				
scbckey     equ 33					; key for cbc

	.code
        startupcode
		
		
		mov ah,3dh       			;open file
        mov al,2         			;read/write mode
        mov dx, offset inp_name 	; name of our file
        int 21h
        jnc  rightcont              ; conditional jump is too short to reach the end of the file ... for some reason (or it was at some point) 
        jmp errlbl
rightcont:
        mov descr,ax

        mov ah,3fh       			; read file
        mov bx,descr    	 		; file descriptor in bx
        mov cx, 256      			; size of our buffer 
        mov dx,offset buf	 		;location of said buffer 
        int 21h
        jnc  rightcont1
        jmp errlbl
rightcont1:
        mov num_read, ax            ; save how many characters have been read
		
		
        ;push ax                    
        ;call VIRJDEC
        ;call VIRJENC
        ;call SENC
        ;call SDEC
        ;call SCBCENC
        ;call SCBCDEC
        ;-------------------------------------------------
                                    ; output buffer like an array 
									; output buffer liek an array, we dont know how full is the bffer is full 			
                                    ; output contents of file for convinience's sake 		
        mov ah,2h                   ; prep it for output mode 
	    mov cx, num_read 			; get number of things in buffer in cx
        lea di,buf                  ; get adress of buffer 
looop:  mov dl,[di]  
        int 21h
        inc di
        dec cx
        jnz looop
;        mov ah,9
;		 mov dx,offset buf
;		 int 21h
 


        mov ah,42h   				; set file pos 0
        mov al,00					 
        mov bx,descr				;load file descriptor in bx
        mov cx,0 					 
        mov dx,0						
        int 21h
        jc errlbl

        mov ah,40h    				;write to file
        mov bx,descr
        mov cx,num_read
        mov dx,offset buf
        int 21h
        jc errlbl


        mov ah,3eh    ; close file
        mov bx,descr
        int 21h
        jc errlbl
	exitcode 0
errlbl:
 	    mov ah,9
        mov dx,offset errmsg
        int 21h
        exitcode 1
;----------------------------------------------------------------

VIRJENC:
        mov ax, num_read
        lea di,buf
        lea si,cword
        mov cx,ax      ; symbols read in ax
        xor bx,bx      ;bl counter
        ;---------------
v_encode:
       mov al,[di]
       mov ah,[si]
       sub ah,'A'-1
       add al,ah
       cmp al,127
       jbe v_cont
       sub al,127-32+1
v_cont:
      mov [di],al
      inc di
      inc si
      inc bl
      cmp bl,keylen ;bl counter
      jb v_moveon
      xor bl,bl
      lea si,cword
v_moveon:
      dec cx
      jnz v_encode
      ret
;------------------------------------------------------------------------
 VIRJDEC:
        mov ax, num_read
        lea di,buf
        lea si,cword
        mov cx,ax      ; symbols read in ax
        xor bx,bx      ;bl counter
        ;---------------
v_decode:
       mov al,[di];bl counter
       mov ah,[si]
       sub ah,'A'-1
       sub al,ah
       cmp al,32
       jae v_goon
       add al,127-32+1
v_goon:
      mov [di],al
      inc di
      inc si
      inc bl
      cmp bl,keylen ;bl counter
      jb v_nextit
      xor bl,bl
      lea si,cword
v_nextit:
      dec cx
      jnz v_decode
      ret
;---------------------------------------------------------------------------
 SENC:
        mov ax, num_read
        lea di,buf
        mov cx,ax      ; symbols read in ax
        ;---------------
s_encode:
       mov al,[di]
       xor al,cmask
       add al,cofs
       mov [di],al
       inc di
       dec cx
       jnz s_encode
       ret
;------------------------------------------------------------------------
 SDEC:
        mov ax, num_read
        lea di,buf
        mov cx,ax       ; symbols read in ax
        ;---------------
s_decode:
       mov al,[di]
       sub al,cofs
       xor al,cmask
       mov [di],al
       inc di
       dec cx
       jnz s_decode
       ret
;-----------------------------------------------------------------------
SCBCENC:
        mov ax, num_read
        lea di,buf
        mov cx,ax      ; symbols read in ax
        mov ah,scbckey
        ;---------------
        ;--description--
        ;1. xor with previous (first sym is scbckey)
        ;2. xor with mask (scbcmask)
        ;3. add offset (sofs)
        ;4. previous = current(ah)
        ;
		; we'll keep prev sym in ah
sc_encode:           
       mov al,[di]
       xor al,ah
       xor al,scbcmask
       add al,sofs
       mov ah,al
       mov [di],al
       inc di
       dec cx
       jnz sc_encode
       ret
;------------------------------------------------------------------------
 SCBCDEC:
        mov ax, num_read
        lea di,buf
        mov cx,ax       ; symbols read in ax
        mov ah,scbckey
        ;---------------
        ;--description--
        ;1.init scbckey
        ;2.get current sym also in bl
        ;3.sub sofs
        ;4.xor smask
        ;5.xor with prev
        ;6.prev = current
        ;
sc_decode:
       mov al,[di]
       mov bl,al
       sub al,sofs
       xor al,scbcmask
       xor al,ah
       mov ah,bl
       mov [di],al
       inc di
       dec cx
       jnz sc_decode
       ret
;-------------------------------------------------------------------------

	END


