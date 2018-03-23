@-------------------------------------------------------------------@
@ Autor: Felipe Escórcio de Sousa 		RA:171043					@
@ Data: 2 semestre - 2017											@
@ e-mail: felipe.escorciosousa@gmail.com 							@
@																	@
@ Camada: bico.s 													@
@ Função: API de controle do Robô Uoli.								@
@																	@
@ 					  -----NO WARRANTIES-----						@
@-------------------------------------------------------------------@



.text
.globl read_sonar
.globl read_sonars
.globl register_proximity_callback
.globl set_motor_speed
.globl set_motors_speed
.globl set_time
.globl get_time
.globl add_alarm



@-------------------------@
@ >>>>>>> SONARES <<<<<<< @
@-------------------------@

@Parametros:
@	r0 - Sonar a ser lido
@Retorno:
@	r0 - distância lida
read_sonar:
	push {r7, lr}
	mov r7, #16
	svc 0x0
	pop {r7, lr}
	mov pc, lr

@Parametros:
@	r0 - primeiro sonar a ser lido 
@	r1 - último sonar a ser lido
@	r2 - vetor com as infos lidas no sonar
@Retorno:
@	Void
read_sonars:
	push {r6-r7, lr}
	mov r6, r0
	sonar_loop:
		cmp r6, r1 
		bgt read_sonars_end
		mov r0, r6 
		mov r7, #16
		svc 0x0
	
		@salva o retorno em um vetor dado
		str r0, [r2], #4

		@volta pro loop
		add r6, r6, #1
		b sonar_loop

	read_sonars_end:
		pop {r6-r7, lr}
		mov pc, lr

@Parametros:
@	r0 - id do sonar
@	r1 - Limiar do sonar
@	r2 - endereço da função a ser chamada
@Retorno:
@	Void
register_proximity_callback:
	push {r7, lr}
	mov r7, #17
	svc 0x0
	pop {r7, lr}
	mov pc, lr



@-------------------------@
@ >>>>>>> MOTORES <<<<<<< @
@-------------------------@

@Parametros
@	r0 - ponteiro para a struct do motor a ser setado
@Retorno
@	Void
set_motor_speed:
	push {r4, r7, lr}
	ldrb r1, [r0]
	mov r4, r0
	mov r0, r1	@id do motor
	ldrb r1, [r4, #1] @velocidade do motor
	mov r7, #18
	svc 0x0
	pop {r4, r7, lr}
	mov pc, lr

@Parametros:
@	r0 - ponteiro para a struct do motor 1
@	r1 - ponteiro para a struct do motor 2
@Retorno:
@	Void
set_motors_speed:
	push {r4-r8, lr}
	ldrb r4, [r0]	
	ldrb r5, [r1]
	mov r6, r0	@ r6 <- &m1
	mov r8, r1  @ r8 <- &m2
	cmp r4, #0		
	ldreqb r0, [r6, #1]	@ r0 <- velocidade de m1 
	ldreqb r1, [r8, #1] @ r1 <- velocidade de m2
	ldrneb r0, [r8, #1]	@ r0 <- velocidade de m2
	ldrneb r1, [r6, #1]	@ r1 <- velocidade de m1
	mov r7, #19
	svc 0x0
	pop {r4-r8, lr}
	mov pc, lr



@------------------------@
@ >>>>>>> TEMPO <<<<<<<< @
@------------------------@

@Parametros:
@	r0 - Tempo a ser setado
@Retorno:
@	Void
set_time:
	push {r7, lr}
	mov r7, #21
	svc 0x0
	pop {r7, lr}
	mov pc, lr

@Parametros:
@	r0 - endereço do valor que deve receber o tempo do sistema
@Retorno:
@	Void
get_time:
	push {r7, lr}
	mov r1, r0
	mov r7, #20
	svc 0x0
	str r0, [r1]
	pop {r7, lr}
	mov pc, lr

@Parametros
@	r0 - ponteiro para a função a ser chamado em caso de alarme
@	r1 - tempo pro alarme ser setado
@Retorno:
@	Void
add_alarm:
	push {r7, lr}
	mov r7, #22
	svc 0x0
	pop {r7, lr}
	mov pc, lr
