.org 0x0
.section .iv, "a"

_start:

interrupt_vector:

	b RESET_HANDLER
.org 0x18
	b IRQ_HANDLER


.org 0x100

.text

RESET_HANDLER:
	
	@desativa as interrupções
	mrs r0, cpsr
	@bic r0, r0, #0x1F
	orr r0, r0, #0xC0
	msr cpsr, r0

	@Zera o contador
    ldr r2, =CONTADOR 
    mov r0, #0
    str r0, [r2]

    @Faz o registrador que aponta para a tabela de interrupções apontar para a tabela interrupt_vector
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0


    @entra em modo IRQ
    mrs r0, cpsr
    orr r0, r0, #0xD2
    msr cpsr, r0 
    
    @ Ajustar a pilha do modo IRQ.   
    ldr r2, =IRQ_STACK
    str r13, [r2]

    @configurando o GPT
    @gpt_cr - habilita e configura clock pra periferico
    ldr r2, =0x53FA0000	
    mov r0, #0x41 
    str r0, [r2] 

    @gpt_pr	- zera o prescaler
    mov r0, #0
    ldr r2, =0x53FA0040	
    str r0, [r2]

    @gpt_cr1 - valor que eu desejo contar 
    mov r0, #100
    ldr r2, =0x53FA0010
    str r0, [r2]

    @gpt_ir - permite interrupcao do gpt
    mov r0, #1
    ldr r2, =0x53FA000C
    str r0, [r2]





    SET_TZIC:
    @ Constantes para os enderecos do TZIC
    .set TZIC_BASE,             0x0FFFC000
    .set TZIC_INTCTRL,          0x0
    .set TZIC_INTSEC1,          0x84 
    .set TZIC_ENSET1,           0x104
    .set TZIC_PRIOMASK,         0xC
    .set TZIC_PRIORITY9,        0x424

    @ Liga o controlador de interrupcoes
    @ R1 <= TZIC_BASE

    ldr	r1, =TZIC_BASE

    @ Configura interrupcao 39 do GPT como nao segura
    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_INTSEC1]

    @ Habilita interrupcao 39 (GPT)
    @ reg1 bit 7 (gpt)

    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_ENSET1]

    @ Configure interrupt39 priority as 1
    @ reg9, byte 3

    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000
    mov r2, #1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    @ Configure PRIOMASK as 0
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Habilita o controlador de interrupcoes
    mov	r0, #1
    str	r0, [r1, #TZIC_INTCTRL]

    @instrucao msr - habilita interrupcoes
    msr  CPSR_c, #0x13       @ SUPERVISOR mode, IRQ/FIQ enabled

    laco:
    	b laco





IRQ_HANDLER:

	push {r0-r3}
	@grava 1 em gpt_sr
	ldr r2, =0x53FA0008
	mov r0, #0x1
	str r0, [r2]

	@incremento de contador
	ldr r2, =CONTADOR
	ldr r0, [r2]
	add r0, r0, #1
	str r0, [r2]

	@subtrai 4 de pc
	sub pc, pc, #4
	movs pc, lr
	pop {r0-r3}



.data
CONTADOR: .word 0x0
.skip 42
IRQ_STACK:

