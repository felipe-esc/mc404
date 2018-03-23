.globl _start

.data

input_buffer:   .skip 32
output_buffer:  .skip 32
    
.text
.align 4

@ Funcao inicial
_start:
    @Chama a funcao "read" para ler 4 caracteres da entrada padrao
    ldr r0, =input_buffer
    mov r1, #5             @ 4 caracteres + '\n'
    bl  read
    mov r4, r0             @ copia o retorno para r4.

    @ Chama a funcao "atoi" para converter a string para um numero
    ldr r0, =input_buffer
    mov r1, r4
    bl  atoi

    @ Chama a funcao "encode" para codificar o valor de r0 usando
    @ o codigo de hamming.
    bl  encode
    mov r4, r0             @ copia o retorno para r4.
	
    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #7
    mov r2, r4
    bl  itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 7)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #7]

    @ Chama a funcao write para escrever os 7 caracteres e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #8         @ 7 caracteres + '\n'
    bl  write



    @Chama a funcao "read" para ler 8 caracteres da entrada padrao
    ldr r0, =input_buffer
    mov r1, #8             @ 7 caracteres + '\n'
    bl  read
    mov r4, r0             @ copia o retorno para r4.

    @ Chama a funcao "atoi" para converter a string para um numero
    ldr r0, =input_buffer
    mov r1, r4
    bl  atoi

    @ Chama a funcao "decode" para decodificar o valor de r0 usando
    @ o codigo de hamming.
    bl  decode
    mov r4, r0             @ copia o retorno para r4.
    mov r5, r1		   @ copia o outro retorno pra r5.
	
    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #4
    mov r2, r4
    bl  itoa


    @ Adiciona o caractere '\n' ao final da sequencia (byte 5)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #4]

    @ Chama a funcao write para escrever os 4 caracteres e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #5         @ 4 caracteres + '\n'
    bl  write

    @ Chama a funcao "itoa" para converter o valor codificado
    @ para uma sequencia de caracteres '0's e '1's
    ldr r0, =output_buffer
    mov r1, #1
    mov r2, r5
    bl itoa

    @ Adiciona o caractere '\n' ao final da sequencia (byte 2)
    ldr r0, =output_buffer
    mov r1, #'\n'
    strb r1, [r0, #1]

    @ Chama a funcao write para escrever o caracter e
    @ o '\n' na saida padrao.
    ldr r0, =output_buffer
    mov r1, #2         @ 1 caracter + '\n'
    bl  write
    	

    @ Chama a funcao exit para finalizar processo.
    mov r0, #0
    bl  exit

@ Codifica o valor de entrada usando o codigo de hamming.
@ parametros:
@  r0: valor de entrada (4 bits menos significativos)
@ retorno:
@  r0: valor codificado (7 bits como especificado no enunciado).
encode:    
       push {r4-r11, lr}
       
       @ <<<<<< ADICIONE SEU CODIGO AQUI >>>>>>	
	@separa os bits	
	and r1, r0, #0b0001 
	and r2, r0, #0b0010 
	and r3, r0, #0b0100
	and r4, r0, #0b1000
	mov r2, r2, lsr #1
	mov r3, r3, lsr #2
	mov r4, r4, lsr #3 
	
	@operações lógicas	
	eor r5, r1, r2	@p1
	eor r5, r5, r4    
	eor r6, r1, r3	@p2
	eor r6, r6, r4
	eor r7, r2, r3	@p3
	eor r7, r7, r4

	@prepara a saída
	and r0, r0, #0
	add r0, r0, r1
	add r0, r0, r5, lsl #6
	add r0, r0, r6, lsl #5
	add r0, r0, r7, lsl #3
	add r0, r0, r2, lsl #1
	add r0, r0, r3, lsl #2
	add r0, r0, r4, lsl #4

       pop  {r4-r11, lr}
       mov  pc, lr

@ Decodifica o valor de entrada usando o codigo de hamming.
@ parametros:
@  r0: valor de entrada (7 bits menos significativos)
@ retorno:
@  r0: valor decodificado (4 bits como especificado no enunciado).
@  r1: 1 se houve erro e 0 se nao houve.
decode:    
       push {r4-r11, lr}
       
       @ <<<<<< ADICIONE SEU CODIGO AQUI >>>>>>
	@separação da entrada	
	and r2, r0, #1
	and r3, r0, #2
	and r4, r0, #4
	and r5, r0, #8
	and r6, r0, #16
	and r7, r0, #32
	and r8, r0, #64

	@verificação dos bits
	eor r8, r8, r6, lsl #2	@p1
	eor r8, r8, r4, lsl #4
	eor r8, r8, r2, lsl #6
	eor r7, r7, r6, lsl #1	@p2
	eor r7, r7, r3, lsl #4
	eor r7, r7, r2, lsl #5
	eor r5, r5, r4, lsl #1	@p3
	eor r5, r5, r3, lsl #2
	eor r5, r5, r2, lsl #3
	orr r8, r8, r7, lsl #1
	orr r8, r8, r5, lsl #3		
	
	@preparação da saída
	and r0, r0, #0
	and r1, r1, #0
	add r0, r0, r2
	add r0, r0, r3
	add r0, r0, r4
	add r0, r0, r6, lsr #1
	mov r1, r8, lsr #6		

       pop  {r4-r11, lr}
       mov  pc, lr

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
    mov r0, #0         @ stdin file descriptor = 0
    mov r1, r4         @ endereco do buffer
    mov r2, r5         @ tamanho maximo.
    mov r7, #3         @ read
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
    mov r0, #1         @ stdout file descriptor = 1
    mov r1, r4         @ endereco do buffer
    mov r2, r5         @ tamanho do buffer.
    mov r7, #4         @ write
    svc 0x0
    pop {r4, r5, lr}
    mov pc, lr

@ Finaliza a execucao de um processo.
@  r0: codigo de finalizacao (Zero para finalizacao correta)
exit:    
    mov r7, #1         @ syscall number for exit
    svc 0x0

@ Converte uma sequencia de caracteres '0' e '1' em um numero binario
@ parametros:
@  r0: endereco do buffer de memoria que armazena a sequencia de caracteres.
@  r1: numero de caracteres a ser considerado na conversao
@ retorno:
@  r0: numero binario
atoi:
    push {r4, r5, lr}
    mov r4, r0         @ r4 == endereco do buffer de caracteres
    mov r5, r1         @ r5 == numero de caracteres a ser considerado 
    mov r0, #0         @ number = 0
    mov r1, #0         @ loop indice
atoi_loop:
    cmp r1, r5         @ se indice == tamanho maximo
    beq atoi_end       @ finaliza conversao
    mov r0, r0, lsl #1 
    ldrb r2, [r4, r1]  
    cmp r2, #'0'       @ identifica bit
    orrne r0, r0, #1   
    add r1, r1, #1     @ indice++
    b atoi_loop
atoi_end:
    pop {r4, r5, lr}
    mov pc, lr

@ Converte um numero binario em uma sequencia de caracteres '0' e '1'
@ parametros:
@  r0: endereco do buffer de memoria que recebera a sequencia de caracteres.
@  r1: numero de caracteres a ser considerado na conversao
@  r2: numero binario
itoa:
    push {r4, r5, lr}
    mov r4, r0
itoa_loop:
    sub r1, r1, #1         @ decremento do indice
    cmp r1, #0          @ verifica se ainda ha bits a serem lidos
    blt itoa_end
    and r3, r2, #1
    cmp r3, #0
    moveq r3, #'0'      @ identifica o bit
    movne r3, #'1'
    mov r2, r2, lsr #1  @ prepara o proximo bit
    strb r3, [r4, r1]   @ escreve caractere na memoria
    b itoa_loop
itoa_end:
    pop {r4, r5, lr}
    mov pc, lr    
