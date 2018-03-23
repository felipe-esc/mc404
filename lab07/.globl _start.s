.globl _start

.data

input_buffer: .skip 16
linha_1: .skip 3068
linha_2: .skip 3068
um: .word 1
output_buffer: skip 36

.text
.align 4

_start:
	mov r0, =input_buffer
	mov r1, #4
	bl read
	mov r4, r0

	@chama função "atoi" pra converter a entrada pra um int
	mov r1, r4
	bl atoi

	@ Chama a funcao exit para finalizar processo.
    mov r0, #0
    bl  exit

@funcao que faz o triangulo de pascal.
pascal:
	pascal_loop:

@ Finaliza a execucao de um processo.
@  r0: codigo de finalizacao (Zero para finalizacao correta)
exit:    
    mov r7, #1         @ syscall number for exit
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

@Funcoes que convertem as entradas   

@Converte a string de entrada pra um int
@parametros:
@	r0: endereco da string
@	r1: numero de caracteres a ser convertido
@retorno:
@	r0: int convertido
atoi:
	push {r4-r11, lr}
	mov r4, r0	@r4 recebe o endereco da entrada
	mov r5, r4  @r5 recebe o numero de caracteres
	mov r0, #0 	@r0 recebe 0
	itoa_loop:


	itoa_fim:
		pop {r4-r11, lr}
		mov pc, lr


itoa:
	