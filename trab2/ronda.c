/*
 * Autor: Felipe Escórcio de Sousa 		RA:171043
 * Data: Segundo semestre de 2017
 * Arquivo: ronda.c
 * Descrição: Faz uma ronda pelo lugar. Primeiro segue reto por um período de tempo, faz uma curva de aproximadamente 90 graus e segue reto novamente por um período de tempo um pouco maior.
 * O processo se repete por 50 vezes e se reinicia.
 */


#include "api_robot2.h"

void vira_direita();
void anda_reto();
void desvia();
void para();
void pega_tempo();

motor_cfg_t motor_direita, motor_esquerda;
int tempo, tempo_base, contador, limiar = 1200;

int _start(){

	/* Por quê o motor 0 é à direita e o 1 à esquerda? nunca saberemos. */
	add_alarm(&pega_tempo, 1);
	tempo = tempo_base;
	motor_esquerda.id = 1;	
	motor_direita.id = 0;
	/* Inicia a ronda andando pra frente. */
	register_proximity_callback(3, limiar, &desvia);
	contador = 0;
	anda_reto();
	while(1){
	}

	return 0;
}
/*
 * Pega o tempo do sistema que servirá de base para o programa
 */
void pega_tempo(){
	get_time(&tempo_base);
}
/*
 * Vira à direita por um determinado tempo.
 * Ao final da escrita registra um alarme pra que se volte a andar em linha reta daqui um certo tempo. 
 */
void vira_direita(){

	int i;

	motor_direita.speed = 0;
	motor_esquerda.speed = 20;
	for(i = 0; i < 5; i++){
		set_motors_speed(&motor_esquerda, &motor_direita);	
	}
	/* Vira a direita por um tempo. */
	for(i = 0; i < 4900000; i++){}
	anda_reto();
	contador++;
	/* Reseta o contador dps de 50 vezes, reseta o tempo do sistema também. */ 	
	if(contador == 50){
		contador = 0;
		set_time(0);
	}
}
/*
 * Prossegue andando em linha reta.
 * Ao final da escrita registra um alarme pra que se faça uma curva à direita daqui um certo tempo.
 */
void anda_reto(){

	int i;

	motor_direita.speed = 20;
	motor_esquerda.speed = 20;
	for(i = 0; i < 5; i++){
		set_motors_speed(&motor_esquerda, &motor_direita);	
	}
 	/* Seta um novo alarme para virar a direita de novo. */
	get_time(&tempo);
	add_alarm(&vira_direita, (tempo*contador) + contador);

}

/*
 * Desvia de um objeto, dado um tempo.
 * Registra uma nova callback para caso se encontre um novo obstáculo.
 * Seta um alarme para que se ande reto novamente.
 */
void desvia(){

	int i;

	motor_direita.speed = 40;
	motor_esquerda.speed = 15;
	for(i = 0; i < 5; i++){
		set_motors_speed(&motor_esquerda, &motor_direita);	
	}
	/* Desvia rapidamente de um obstáculo, virando até que sua frente esteja obstruída. */
	while(read_sonar(3) < limiar){
		for(i = 0; i < 2000000; i++){
		}
	}
	register_proximity_callback(3, limiar, desvia);

}
/*
 * Para.
 */
void para(){

	int i;

	motor_esquerda.speed = 0;
	motor_direita.speed = 0;
	for(i = 0; i < 5; i++){
		set_motors_speed(&motor_esquerda, &motor_direita);	
	}

	return;
}