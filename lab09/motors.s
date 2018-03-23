@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@ Codigo de exemplo para controle basico de um robo.
@ Este codigo le os valores de 2 sonares frontais para decidir se o
@ robo deve parar ou seguir em frente.
@ 2 syscalls serao utilizadas para controlar o robo:
@   write_motors  (syscall de numero 124)
@                 Parametros:
@                       r0 : velocidade para o motor 0  (valor de 6 bits)
@                       r1 : velocidade para o motor 1  (valor de 6 bits)
@
@  read_sonar (syscall de numero 125)
@                 Parametros:
@                       r0 : identificador do sonar   (valor de 4 bits)
@                 Retorno:
@                       r0 : distancia capturada pelo sonar consultado (valor de 12 bits)
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

        
.text
.align 4
.globl _start

_start:                         @ main
        
        mov r0, #0              @ Carrega em r0 a velocidade do motor 0.
                                @ Lembre-se: apenas os 6 bits menos significativos
                                @ serao utilizados.
        mov r1, #0              @ Carrega em r1 a velocidade do motor 1.
        mov r7, #124            @ Identifica a syscall 124 (write_motors).
        svc 0x0                 @ Faz a chamada da syscall.

        ldr r6, =1200           @ r6 <- 1200 (Limiar para parar o robo)

loop:   
        mov r0, #5
        mov r7, #125
        svc 0x0
        cmp r0, r6
        blt vira

        mov r0, #2
        mov r7, #125
        svc 0x0
        cmp r0, r6
        blt vira

        mov r0, #3              
        mov r7, #125            
        svc 0x0                 
        cmp r0, r6
        blt vira              

        mov r0, #4              
        mov r7, #125
        svc 0x0
        cmp r0, r6
        blt vira

        mov r0, #36            
        mov r1, #36
        mov r7, #124        
        svc 0x0

        b loop                  @ Refaz toda a logica
        

vira:   
        @decide se vira pra esquerda ou direita
        mov r0, #1
        mov r7, #125
        svc 0x0
        @ve se pode virar a esquerda, senao vira a direita por default
        cmp r0, r6
        bge vira_esq

vira_dir:
        mov r0, #0
        mov r1, #10              @move apenas uma das rodas
        mov r7, #124
        svc 0x0
        dir_loop:                @vira enquanto a lateral não estiver paralela ao obstaculo
                mov r0, #4
                mov r7, #125
                svc 0x0
                cmp r0, r6
                ble dir_loop  

        mov r0, #36
        mov r1, #36
        mov r7, #124
        svc 0x0
        b loop

vira_esq:
        mov r1, #0
        mov r0, #10
        mov r7, #124
        svc 0x0
        esq_loop:
                mov r0, #3
                mov r7, #125
                svc 0x0
                cmp r0, r6
                ble esq_loop

        mov r0, #36
        mov r1, #36
        mov r7, #124
        svc 0x0
        b loop

