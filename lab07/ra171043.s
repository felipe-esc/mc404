.globl _start

.data

input_buffer: .skip 16
linha_1: .skip 3068
linha_2: .skip 3068
output_buffer: .skip 36

.text
.align 4

_start:
	ldr r0, =input_buffer
	mov r1, #4
	bl read
	mov r4, r0

	@chama função "atoi" pra converter a entrada pra um int
	ldr r0, =input_buffer
	mov r1, r4
	bl atoi
	mov r4, r0

	@chama a funcao que calcula e imprime o triangulo de pascal
	ldr r0, =output_buffer
	mov r1, r4
	ldr r2, =linha_1
	ldr r3, =linha_2
	bl pascal

	@chama a funcao exit para finalizar processo.
    mov r0, #0
    bl  exit

@funcao que faz o triangulo de pascal.
@parametros:
@	r0: output_buffer
@	r1: numero de linhas a serem impressas
@	r2: endereco da linha 1
@	r3: endereco da linha 2
pascal:
	push {r4-r11, lr}
	mov r8, r0			@r8 = output_buffer
	mov r4, r1 			@r4 = linhas	
	mov r6, #0			@r6 = contador
	mov r5, #0 			@r5 = elem da linha
	pascal_loop:
		cmp r6, r4
		beq pascal_exit
		cmp r5, #0
		beq pontas 
		cmp r5, r6
		beq pontas
		bne outros
		pontas:
			mov r9, #1	@r9 = aux
			mov r0, r8
			mov r1, r9	
			bl itoa
			cmp r5, #0			@verifica se e o primeiro 
			addne r6, r6, #1
			movne r5, #0
			movne r7, r3		@troca as linhas
			movne r3, r2
			movne r2, r7
			moveq r9, #' '		@primeiro
			movne r9, #'\n'		@ultimo
			addeq r5, r5, #1
			cmp r6, #0			@primeira linha
			moveq r9, #'\n'
			moveq r5, #0
			addeq r6, r6, #1
			mov r0, r8
    		strb r9, [r0, #8]
    		b pascal_write
		outros:
			ldr r10, [r2, r5]	@ r10 = l1[n]
			sub r6, r5, #1		
			ldr r10, [r2, r6]	@ r11 = l1[n-1]
			add r9, r10, r11
			mov r0, r8
			mov r1, r9	
			bl itoa
			add r6, r6, #1
			mov r9, #' '
			mov r0, r8
			strb r9, [r0, #8]
		pascal_write:
			mov r0, r8
			mov r1, #9
			bl write
			add r5, r5, #1
			b pascal_loop
	pascal_exit:
		pop {r4-r11, lr}
		mov pc, lr

@ Finaliza a execucao de um processo.
@  r0: codigo de finalizacao (Zero para finalizacao correta)
exit:    
    mov r7, #1         	@ syscall number for exit
    svc 0x0

@ Le uma sequencia de bytes da entrada padrao.
@ parametros:
@  r0: endereco do buffer de memoria que recebera a sequencia de bytes.
@  r1: numero maximo de bytes que pode ser lido (tamanho do buffer).
@ retorno:
@  r0: numero de bytes lidos.
read:
    push {r4,r5, lr}
    mov r4, r0
    mov r5, r1
    mov r0, #0         	@ stdin file descriptor = 0
    mov r1, r4         	@ endereco do buffer
    mov r2, r5         	@ tamanho maximo.
    mov r7, #3         	@ read
    svc 0x0
    pop {r4, r5, lr}
    mov pc, lr

@ Escreve uma sequencia de bytes na saida padrao.
@ parametros:
@  r0: endereco do buffer de memoria que contem a sequencia de bytes.
@  r1: numero de bytes a serem escritos
write:
    push {r4,r5, lr}
    mov r4, r0
    mov r5, r1
    mov r0, #1         	@ stdout file descriptor = 1
    mov r1, r4         	@ endereco do buffer
    mov r2, r5         	@ tamanho do buffer.
    mov r7, #4         	@ write
    svc 0x0
    pop {r4, r5, lr}
    mov pc, lr

@Funcoes que convertem as entradas   

@Converte a string de entrada pra um int
@parametros:
@	r0: endereco da string
@	r1: numero de caracteres a ser convertido(até 3)
@retorno:
@	r0: int convertido
atoi:
	push {r4-r5, lr}
	mov r4, r0			@r4 recebe o endereco da entrada
	mov r5, r1  		@r5 recebe o numero de caracteres
	mov r0, #0 			@r0 recebe 0
	mov r1, #0	
	atoi_loop:
		cmp r1, r5
		beq atoi_fim	@fim da conversão
		ldrb r2, [r4, r1]
		mov r0, r0, lsl #4

		@identifica o numero
		cmp r2, #'0'
		moveq r2, #0
		cmp r2, #'1'
		moveq r2, #1
		cmp r2, #'2'
		moveq r2, #2
		cmp r2, #'3'
		moveq r2, #3
		cmp r2, #'4'
		moveq r2, #4
		cmp r2, #'5'
		moveq r2, #5
		cmp r2, #'6'
		moveq r2, #6
		cmp r2, #'7'
		moveq r2, #7
		cmp r2, #'8'
		moveq r2, #8
		cmp r2, #'9'
		moveq r2, #9
		cmp r2, #'A'
		moveq r2, #0xA
		cmp r2, #'B'
		moveq r2, #0xB
		cmp r2, #'C'
		moveq r2, #0xC
		cmp r2, #'D'
		moveq r2, #0xD
		cmp r2, #'E'
		moveq r2, #0xE
		cmp r2, #'F'	
		moveq r2, #0xF

		@adiciona r2 a r0, nossa saida
		add r0, r0, r2  
		add r1, r1, #1
		b atoi_loop
	atoi_fim:
		pop {r4-r5, lr}
		mov pc, lr

@Converte um int em uma string de 8 números hexadecimais
@ parametros:
@	r0: endereco do buffer de memoria que recebera a sequencia de caracteres
@	r1: numero a ser convertido
@ retorno:
@	r0: endereco da string convertida.
itoa:
	push {r4, lr}
	mov r4, r0
	mov r2, #8					@conta quantos caracteres vamos ter
	itoa_loop:
		sub r2, r2, #1
		cmp r2, #0				@pode haver no max 8 caracteres
		blt itoa_fim
		and r3, r1, #0xF

		@compara o numero
		cmp r3, #0
		moveq r3, #'0'
		cmp r3, #1
		moveq r3, #'1'
		cmp r3, #2
		moveq r3, #'2'
		cmp r3, #3
		moveq r3, #'3'
		cmp r3, #4
		moveq r3, #'4'
		cmp r3, #5
		moveq r3, #'5'
		cmp r3, #6
		moveq r3, #'6'
		cmp r3, #7
		moveq r3, #'7'
		cmp r3, #8
		moveq r3, #'8'
		cmp r3, #9
		moveq r3, #'9'
		cmp r3, #0xA
		moveq r3, #'A'
		cmp r3, #0xB
		moveq r3, #'B'
		cmp r3, #0xC
		moveq r3, #'C'
		cmp r3, #0xD
		moveq r3, #'D'
		cmp r3, #0xE
		moveq r3, #'E'
		cmp r3, #0xF
		moveq r3, #'F'

		mov r1, r1, lsr #4
		strb r3, [r4, r2]		@poe caractere na memoria
		b itoa_loop
	itoa_fim:
		pop {r4, lr}
		mov pc, lr
