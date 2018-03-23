
@-------------------------------------------------------------------@
@ Autor: Felipe Escórcio de Sousa 		RA:171043					@
@ Data: 2 semestre - 2017											@
@ e-mail: felipe.escorciosousa@gmail.com 							@
@																	@
@ Camada: soul.s 													@
@ Função: Proto-S.O. do robô Uóli. Gerencia syscalls e interrupções @
@ de hardware.														@
@																	@
@ 					  -----NO WARRANTIES-----						@
@-------------------------------------------------------------------@


.org 0x0
.section .iv, "a"

_start:

@ Vetor de interrupções.
interrupt_vector:
	b RESET_HANDLER
.org 0x8	
	b SWI_HANDLER
.org 0x18
	b IRQ_HANDLER


.org 0x100

.text

@ Configuração ao iniciar a placa.
RESET_HANDLER:

	@ Desativa as interrupções
	mrs r0, cpsr
	orr r0, r0, #0xC0
	msr cpsr, r0

	@ Faz o registrador que aponta para a tabela de interrupções apontar para a tabela interrupt_vector
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0


    @----------------------------------@
	@ >>>>>>> CONFIGURA O GPT <<<<<<<< @
	@----------------------------------@

    SET_GPT:
    @ Endereços dos registradores do GPT.
    .equ GPT_CR, 	0x53FA0000
    .equ GPT_PR, 	0x53FA0040
    .equ GPT_CR1, 	0x53FA0010
    .equ GPT_IR, 	0x53FA000C
    .equ GPT_SR, 	0x53FA0008

    @ gpt_cr - habilita e configura clock pra periférico.
    ldr r2, =GPT_CR	
    mov r0, #0x41 
    str r0, [r2] 

    @ gpt_pr	- zera o prescaler.
    mov r0, #0
    ldr r2, =GPT_PR	
    str r0, [r2]

    @ gpt_cr1 - valor que eu desejo contar.
    ldr r0, =TIME_SZ
    ldr r2, =GPT_CR1
    str r0, [r2]

    @ gpt_ir - permite interrupcao do gpt
    mov r0, #1
    ldr r2, =GPT_IR
    str r0, [r2]

    @ Seta o tempo inicial do sistema.
    mov r0, #0
    ldr r2, =SYSTEM_TIME
    str r0, [r2]


	@-----------------------------------@
	@ >>>>>>> CONFIGURA O TZIC <<<<<<<< @
	@-----------------------------------@

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

    @ Configure PRIOMASK as 0.
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Habilita o controlador de interrupções.
    mov	r0, #1
    str	r0, [r1, #TZIC_INTCTRL]



    @-----------------------------------@
	@ >>>>>>> CONFIGURA O GPIO <<<<<<<< @
	@-----------------------------------@

    SET_GPIO:
    @ Endereços dos registradores do GPIO e máscara de configuração dos pinos.
    .equ GPIO_DR, 		0x53F84000
    .equ GPIO_GDIR,		0x53F84004
    .equ GPIO_PSR, 		0x53F84008
    .equ GPIO_IO_MASK,	0xFFFC003E 

    @ Seta os bits em GPIO_GDIR para configurar quais pinos são entradas ou saídas.
    ldr r2, =GPIO_GDIR
    ldr r0, =GPIO_IO_MASK    
    str r0, [r2]


    @-----------------------------------@
	@ >>>>>>> AJUSTA VARIÁVEIS <<<<<<<< @	
	@-----------------------------------@

	@ Zera o número de callbacks ativas.
	ldr r2, =ACTIVE_CALLBACKS
	mov r0, #0
	str r0, [r2]

	@ Zera o número de alarmes ativos.
	ldr r2, =ACTIVE_ALARMS
	str r0, [r2]

	@ Seta a flag de tratamento de interrupção como zero.
	ldr r2, =TREATING_FUNCTION
	str r0, [r2]



	@-----------------------------------@
	@ >>>>>>> AJUSTA AS PILHAS <<<<<<<< @
	@-----------------------------------@

    @ Entra em modo IRQ e desativa interrupções.
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0xD2
    msr cpsr, r0 
    
    @ Ajusta a pilha do modo IRQ.   
    ldr sp, =IRQ_STACK

    @ Entra em modo System.
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x1F
    msr cpsr, r0

    @ Ajusta pilha de System/User.
    ldr sp, =SWI_STACK

    @ Entra em modo usuário, habilita interrupções e vai pra começo do programa do usuário.
    mrs r0, cpsr
    bic r0, r0, #0xDF
    orr r0, r0, #0x10
    msr cpsr, r0
    ldr r1, =USER_CODE
    mov pc, r1 	@vai pro código de usuário





	@ Constantes
    .set TIME_SZ,		170
    .set MAX_CALLBACKS, 8
    .set MAX_ALARMS,	8
    .set USER_CODE,		0x77812000





@ Trata chamadas a funções que fazem uso do modo supervisor.
@ Aqui vão as chamadas de sistema feitas pela api. 
SWI_HANDLER:
	

	@ Compara e descobre qual chamada foi feita.
	cmp r7, #16
	beq _READ_SONAR_
	cmp r7, #17
	beq _REGISTER_PROXIMITY_CALLBACK_
	cmp r7, #18
	beq _SET_MOTOR_SPEED_
	cmp r7, #19
	beq _SET_MOTORS_SPEED_
	cmp r7, #20
	beq _GET_TIME_
	cmp r7, #21
	beq _SET_TIME_
	cmp r7, #22
	beq _SET_ALARM_
	cmp r7, #42
	beq _IRQ_BACK_
	bne return


	@ Syscall 16 - Read Sonar
	@ 	Descrição: 
	@ 		Faz a leitura de algum sonar escolhido, e retorna a distância do sonar até o obstáculo mais próximo.
	@	Parâmetros:
	@		r0 - Identificador do sonar a ser lido(0-15).
	@	Retono: 
	@		r0 - Valor obtido a partir da leitura do sonar até o próximo obstáculo, retorna -1 em caso de sonar inválido. 
	_READ_SONAR_:

		@ Sonar inválido.
		cmp r0, #15
		movhi r0, #-1
		bhi sonar_return

		push {r4-r8}

		ldr r4, =GPIO_DR
		ldr r5, [r4]
		bic r5, r5, #0x3C 		@ zera mux anterior se houver
		orr r5, r5, r0, lsl #2 	@ Sonar Mux <- Sonar Id
		mov r6, #200			@ Contador pro delay.
		bic r5, r5, #0x2 		@ trigger <- 0
		str r5, [r4]
		@ delay
		trigger_loop1:	
			sub r6, r6, #1
			cmp r6, #0
			bne trigger_loop1
		mov r6, #200
		orr r5, r5, #0x2 	@ trigger <- 1
		str r5, [r4]
		@ delay 2
		trigger_loop2:
			sub r6, r6, #1
			cmp r6, #0
			bne trigger_loop2
		bic r5, r5, #0x2 	@ trigger <- 0
		str r5, [r4]
		ldr r4, =GPIO_DR
		flag_loop:
			ldr r5, [r4]	@ lê DR
			and r8, r5, #0x1 	
			cmp r8, #0x1 	@ flag == 1?
			beq read_sonar_end
			mov r6, #150
			flag_delay:
				sub r6, r6, #1
				cmp r6, #0
				bne flag_delay
			ldr r5, [r4]
			and r8, r5, #0x1 	
			cmp r8, #0x1 	@ flag == 1?
			bne flag_loop

		@ Lê o valor do sonar de PSR. 
		read_sonar_end:
			ldr r4, =GPIO_PSR
			ldr r5, [r4]
			mov r0, r5, lsr #6
			pop {r4-r8}

		sonar_return:
			movs pc, lr


	@ Syscall 17 - Register Proximity Callback
	@	Descrição:
	@		Registra uma função a ser chamada caso o robô se aproxime de um objeto a uma distância menor que o limiar, dado um determinado sonar.
	@	Parâmetros:
	@		r0 - Identificador do sonar. 
	@		r1 - Limiar de distância.
	@		r2 - Ponteiro para função a ser chamada em caso de ocorrência de alarme.
	@	Retorno:
	@		r0 - Retorna -1 caso o número de callbacks máximo ativo no sistema seja maior do que MAX_CALLBACKS. -2 caso o identificador do sonar seja inválido. Caso contrário retorna 0.
	_REGISTER_PROXIMITY_CALLBACK_:
		
		push {r4-r6, lr}

		@ Id de sonar inválido.
		cmp r0, #15
		movhi r0, #-2
		bhi reg_callback_return

		@ num máximo de callbacks ativas atingido.
		ldr r4, =ACTIVE_CALLBACKS
		ldr r6, [r4]
		ldr r5, =MAX_CALLBACKS
		cmp r6, r5
		moveq r0, #-1
		beq reg_callback_return

		@ coloca os dados da callback no vetor de callbacks.
		ldr r5, =CALLBACKS_IDS
		strb r0, [r5, r6]
		ldr r5, =CALLBACKS_FUNCTIONS
		str r2, [r5, r6, lsl #2]
		ldr r5, =CALLBACKS_THRESHOLDS
		mov r6, r6, lsl #1
		strh r1, [r5, r6]

		@ incrementa o número de callbacks ativas.
		add r6, r6, #1
		str r6, [r4]

		mov r0, #0	@ Ok - retorna 0.
	
		reg_callback_return:
			pop {r4-r6, lr}
			movs pc, lr


	@ Syscall 18 - Set Motor Speed
	@	Descrição:
	@		Define a velocidade para um dos motores do robô.
	@	Parâmetros:
	@		r0 - Identificador do motor.
	@		r1 - Velocidade a ser definida.
	@	Retorno:
	@		r0 - Retorna -1 caso o identificador do motor seja inválido, -2 caso a velocidade seja inválida, 0 caso Ok.
	_SET_MOTOR_SPEED_: 
		
		@ Id do motor inválido.
		cmp r0, #0
		movlt r0, #-1
		blt motor_return
		cmp r0, #1
		movgt r0, #-1
		bgt motor_return

		@ Velocidade inválida.
		cmp r1, #0x3F 	@63 é a velocidade máxima que pode ser escrita, visto que temos 6 pinos para a velocidade.
		movhi r0, #-2
		bhi motor_return

		push {r4-r6}

		@ Escrita no motor.
		ldr r4, =GPIO_DR
		ldr r5, [r4]
		mov r6, #0x1
		cmp r0, #0
		@ Apaga velocidade anterior de um dos motores.
		mov r7, #0x3F
		biceq r5, r5, r7, lsl #19
		bicne r5, r5, r7, lsl #26
		@ Seta uma nova velocidade para um dos motores.
		orreq r5, r1, r5, lsl #19   @ motor0 speed <- r0
		orrne r5, r1, r5, lsl #26	@ motor1 speed <- r1
		orreq r5, r5, r6, lsl #25	@ write1 = 1 - não escreve
		orrne r5, r5, r6, lsl #18	@ write0 = 1 - não escreve
		biceq r5, r5, r6, lsl #18	@ write0 = 0 - escreve
		bicne r5, r5, r6, lsl #25   @ write1 = 0 - escreve
		str r5, [r4] 

		pop {r4-r6}
		mov r0, #0 		@Ok - retorno 0.

		motor_return:
			movs pc, lr


	@ Syscall 19 - Set Motors Speed
	@	Descrição:
	@		Define uma velocidade para os dois motores ao mesmo tempo.
	@	Parâmetros:
	@		r0 - Velocidade a ser definida para o motor 0(esquerda).
	@		r1 - Velocidade a ser definida para o motor 1(direita).
	@	Retorno:
	@		r0 - Retorna -1 caso a velocidade para o motor 0 seja inválida, -2 caso a velocidade para o motor 1 seja inválida, 0 caso Ok.
	_SET_MOTORS_SPEED_:

		@ Velocidade inválida.
		cmp r0, #0x3F
		movhi r0, #-1
		bhi motors_return
		cmp r1, #0x3F 	
		movhi r0, #-2
		bhi motors_return

		push {r4-r6}

		@ Escrita nos motores.
		ldr r4, =GPIO_DR
		mov r6, #0x1
		mov r5, #0
		orr r5, r5, r0, lsl #19		@ motor0 speed <- r0
		orr r5, r5, r1, lsl #26	  	@ motor1 speed <- r1
		bic r5, r5, r6, lsl #18	 	@ write0 = 0 - escreve
		bic r5, r5, r6, lsl #25  	@ write1 = 0 - escreve
		str r5, [r4]	@ escreve

		mov r0, #0	@ Ok - retorna 0
		pop {r4-r6}

		motors_return:
			movs pc, lr


	@ Syscall 20 - Get Time
	@	Descrição:
	@		Busca o tempo atual do sistema.
	@	Parâmetros:
	@		N/A
	@	Retorno:
	@		r0 - Retorna o tempo do sistema. 
	_GET_TIME_:
		
		push {r4}

		@ Carrega o tempo de sistema.
		ldr r4, =SYSTEM_TIME
		ldr r0, [r4]

		pop {r4}
		movs pc, lr


	@ Syscall 21 - Set Time
	@	Descrição:
	@		Define um novo tempo para o sistema.
	@	Parâmetros:
	@		r0 - Novo tempo a ser definido.
	@	Retorno:
	@		N/A
	_SET_TIME_:

		push {r4}

		@ Salva um novo tempo de sistema.
		ldr r4, =SYSTEM_TIME
		str r0, [r4]
		
		pop {r4}
		movs pc, lr


	@ Syscall 22 - Set Alarm
	@ 	Descrição:
	@		Define um novo alarme a ser chamado ao se atingir um tempo determinado no sistema. Ao ser atingido esse dado tempo, chama uma função escolhida.
	@	Parâmetros:
	@		r0 - Ponteiro da função a ser chamada ao se atingir o dado tempo.
	@		r1 - Tempo a ser chamado o alarme.
	@	Retorno:
	@		r0 - Retorna -1 caso o número de alarmes máximo ativo no sistema seja maior do que MAX_ALARMS. -2 caso o tempo seja menor do que o tempo atual do sistema. Caso contrário retorna 0.
	_SET_ALARM_:
		
		push {r4-r6}

		@ trata máximo de alarmes ativos atingido.
		ldr r4, =ACTIVE_ALARMS
		ldr r6, [r4]
		ldr r5, =MAX_ALARMS
		cmp r6, r5
		moveq r0, #-1
		beq alarm_return

		@tempo menor que no sistema.
		ldr r5, =SYSTEM_TIME
		ldr r5, [r5]
		cmp r1, r5
		movls r0, #-2
		bls alarm_return

		@ Habilitar um novo alarme.
		ldr r5, =ALARMS_TIMES
		str r1, [r5, r6, lsl #2]
		ldr r5, =ALARMS_FUNCTIONS
		str r0, [r5, r6, lsl #2]
		
		@ Incrementa o contador de alarmes.
		add r6, r6, #1
		str r6, [r4]

		@ Ok - retorna 0
		mov r0, #0

		alarm_return:
			pop {r4-r6}
			movs pc, lr


	@ Syscall 42 - back to IRQ mode.
	@ 	Descrição: 
	@		Volta pra modo IRQ, pois ao tratar um código de usuário chamado por um alarme ou syscall devemos voltar para modo IRQ para continuar tratando-o.
	@ 	Parâmetros:
	@ 		N/A
	@ 	Retorno: 
	@		N/A
	_IRQ_BACK_:
		mrs r7, cpsr
		bic r7, r7, #0x1F
		orr r7, r7, #0x12
		msr cpsr, r7
		mov pc, lr


	@ Só retorna caso nenhuma syscall corresponda à chamada.
	return:
		movs pc, lr



@Trata interrupções de hardware.
IRQ_HANDLER:
	
	push {r0-r9, lr}

	@ Grava 1 em gpt_sr.
	ldr r2, =0x53FA0008
	mov r0, #0x1
	str r0, [r2]

	@ Incremento de contador.
	ldr r2, =SYSTEM_TIME
	ldr r0, [r2]
	add r0, r0, #1
	str r0, [r2]

	@ Verifica se uma callback ou alarme está em tratemento. 1 == função em tratamento.
	ldr r2, =TREATING_FUNCTION
	ldrb r1, [r2] 
	cmp r1, #1
	beq irq_back

	@ Verifica se há alarmes habilitados.
	ldr r2, =ACTIVE_ALARMS
	ldrb r1, [r2]
	cmp r1, #0
	beq callback_checkout

	@ Verifica se algum dos alarmes estão prontos para serem chamados.
	mov r3, #0
	ldr r2, =ALARMS_TIMES
	alarm_loop:
		ldr r4, [r2, r3, lsl #3]	@ Carrega tempo do alarme.
		cmp r0, r4 					@ System Time > Alarm time?
		blge alarm_call				
		add r3, r3, #1				@ Verifica se há próximo alarme.
		cmp r3, r1
		bls alarm_loop

	@ Verifica se há callbacks habilitadas.
	callback_checkout:
		ldr r2, =ACTIVE_CALLBACKS
		ldrb r1, [r2]
		cmp r1, #0
		beq irq_back

	@ Verifica as diferentes callbacks
	mov r3, #0		
	ldr r4, =CALLBACKS_IDS
	ldr r5, =CALLBACKS_THRESHOLDS
	callback_loop:
		ldrb r0, [r4, r3]	@ Carrega um Id de sonar
		mov r7, #16
		svc 0x0 			@ lê sonar

		@carrega os dados
		mov r6, r3, lsl #1
		ldrh r9, [r5, r6]	@ Carrega um Limiar
		cmp r0, r9 			@ dist < limiar?
		blls callback_call
		add r3, r3, #1
		cmp r3, r1 			@ count < num de callbacks?
		bne callback_loop

	@ Volta pro código que estava antes de ser interrompido e reabilita IRQ.
	irq_back:
	@ Subtrai 4 de pc e volta.
		pop {r0-r9, lr}
		sub lr, lr, #4
		movs pc, lr




	@ Chama uma alarme setado.
	@ Registradores já sendo usados:
	@	> r3 - num do alarme
	@	> r2 - endereço dos tempos
	@ 	> r1 - num de alarmes
	@ 	> r0 - tempo atual do sistema
	alarm_call:
	
	push {r4-r7, lr}

	@ Seta variável dizendo que uma função já está sendo chamada.
	ldr r4, =TREATING_FUNCTION
	mov r6, #1
	strb r6, [r4]

	@ Entra em modo usuário.
	mrs r4, cpsr
	bic r4, r4, #0x9F
	orr r4, r4, #0x10
	msr cpsr, r4

	@ Chama a função do usuário.
	ldr r4, =ALARMS_FUNCTIONS
	ldr r5, [r4, r3, lsl #2]	@ Carrega o ponteiro pra função. 
	blx r5

	@ Volta pro modo IRQ. 
	mov r7, #42
	svc 0x0

	@ Retira um alarme do array 
	add r5, r3, #1
	mov r7, r3
	alarm_deletion:
		ldr r6, [r2, r5, lsl #2]	@ Traz o prox tempo.
		str r6, [r2, r7, lsl #2]	@ Salva na posição atual.
		ldr r6, [r4, r5, lsl #2]	@ Traz a prox função uma posição
		str r6, [r4, r7, lsl #2]	@ Salva na posição atual.
		add r5, r5, #1
 		add r7, r7, #1
		cmp r5, r1
		bls alarm_deletion

	@ Diminui o número de alarmes ativos
	ldr r5, =ACTIVE_ALARMS
	sub r7, r7, #1
	str r7, [r5]

	@ Reseta a variável de tratamento de interrupção
	ldr r4, =TREATING_FUNCTION
	mov r6, #0
	strb r6, [r4]

	@ Volta pro tratamento de IRQ.
	pop {r4-r7, lr}
	mov pc, lr




	@ Chama uma callback.
	@ Registradores setados:
	@ 	> r5 - endereço dos limiares
	@ 	> r4 - endereço dos ids
	@ 	> r3 - num callback atual
	@ 	> r2 - end do num de callbacks
	@ 	> r1 - num de callbacks
	@ 	> r0 - última leitura
	callback_call:
	push {r6-r10, lr}

	@ Seta variável dizendo que uma função já está sendo chamada.
	ldr r6, =TREATING_FUNCTION
	mov r8, #1
	strb r8, [r6]

	@ Entra em modo usuário.
	mrs r6, cpsr
	bic r6, r6, #0x9F
	orr r6, r6, #0x10
	msr cpsr, r6

	@ Chama a função do usuário. 
	ldr r6, =CALLBACKS_FUNCTIONS
	ldr r7, [r6, r3, lsl #2]
	blx r7

	@ Volta pro modo IRQ.
	mov r7, #42
	svc 0x0

	@ Retira o registro de uma callback dos arrays.
	mov r8, r3
	add r7, r8, #1
	callback_deletion:
		ldrb r9, [r4, r7]			@ Traz o prox id.
		strb r9, [r4, r8]			@ Salva na posição atual.
		mov r10, r7, lsl #1
		ldrh r9, [r5, r10]			@ Traz o prox limiar.
		mov r10, r8, lsl #1
		strh r9, [r5, r10]			@ Salva na posição atual.
		ldr r9,	[r6, r7, lsl #2]	@ Traz um ponteiro de função.
		str r9, [r6, r8, lsl #2]	@ Salva na posição atual.
		mov r8, r7
		add r7, r7, #1
		cmp r8, r1
		bls callback_deletion

	@ Diminui o número de Callbacks ativas.
	sub r8, r8, #1
	str r8, [r2]

	@ Reseta a variável de tratamento de interrupção.
	ldr r6, =TREATING_FUNCTION
	mov r8, #0
	strb r8, [r6]

	@ Volta pro tratemento do mesmo.
	pop {r6-r10, lr}
	mov pc, lr





.data

@ pilhas dos modos.
.skip 0x200
SWI_STACK:
.skip 0x200
IRQ_STACK:
@ Variáveis do sistema.
SYSTEM_TIME: .skip 4	
ACTIVE_CALLBACKS: .skip 1
ACTIVE_ALARMS: .skip 1
TREATING_FUNCTION: .skip 1

.align 4
@ vetores de alarmes e callbacks
CALLBACKS_IDS: .skip 8
CALLBACKS_THRESHOLDS: .skip 16
CALLBACKS_FUNCTIONS: .skip 32
ALARMS_TIMES: .skip 32	
ALARMS_FUNCTIONS: .skip 32
