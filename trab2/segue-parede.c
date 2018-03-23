/*
 * Autor: Felipe Escórcio de Sousa 		RA:171043
 * Data: Segundo semestre de 2017
 * Arquivo: segue_parede.c
 * Descrição: Procura uma parede e a rodeia.
 */

#include "api_robot2.h"

void procura_parede();
void segue_parede();
void vira_direita();
void anda_reto();
void para();
void ajusta();


motor_cfg_t motor_direita, motor_esquerda;
int parede = 0, limiar = 900;

int _start(){

	motor_esquerda.id = 1;
	motor_direita.id = 0;
	procura_parede();

	return 0;
}

/*
 * Anda até encontrar a primeira parede, e a partir daí começar a andar seguindo a parede.
 */
void procura_parede(){

	int i;

	anda_reto();
	/* Seta callback pra quando encontrar uma parede parar e fazer uma curva para a esquerda */
	register_proximity_callback(3, limiar, &para);
	/* Enquanto não achar uma parede ele não para. */
	while(!parede){
	}
	vira_direita();
	segue_parede();

	return;
}

/* 
 * Anda perto de uma parede, contornando-a ad infinitum.
 */ 
void segue_parede(){

	int i;

	/* Anda em frente e vai checando se não precisa ajustar sua posição em relação à parede. */
	anda_reto();
	while(1){	
		if(read_sonar(0) > limiar){
			ajusta();
		}
		for(i = 0; i < 500000; i++){}
		anda_reto();	
	}

	return;
}

/*
 * Vira à direita por um determinado tempo.
 */
void vira_direita(){

	int i;

	motor_esquerda.speed = 15;
	motor_direita.speed = 0;
	/* garante que a velocidade vai ser escrita. */
	for(i = 0; i < 3; i++){
		set_motors_speed(&motor_esquerda, &motor_direita);	
	}
	/* Enquanto sua frente não estiver livre ele vira. */
	while(read_sonar(3) < limiar){
		set_motors_speed(&motor_esquerda, &motor_direita);
		/* Delay pra ler o sonar de novo. */
		for(i = 0; i < 5000000; i++){
		} 	
	}
	/* seta callback novamente. */
	register_proximity_callback(3, limiar, &vira_direita);

	return;
}

/*
 * Prossegue andando em linha reta.
 */
void anda_reto(){

	int i;

	motor_esquerda.speed = 15;
	motor_direita.speed = 15;
	for(i = 0; i < 3; i++){
		set_motors_speed(&motor_esquerda, &motor_direita);	
	}

	return;
}

/*
 * Para.
 */
void para(){

	int i;

	motor_esquerda.speed = 0;
	motor_direita.speed = 0;
	for(i = 0; i < 3; i++){
		set_motors_speed(&motor_esquerda, &motor_direita);
	}
	/* encontra a parede e a marca. */
	parede = 1;

	return;
}

/*
 * Ajusta a direção do Uoli até que ele esteja novamente de lado para a parede.
 */
void ajusta(){

	int i, sonar;

	sonar = 0;
	motor_direita.speed = 15;
	motor_esquerda.speed = 0;
	/* Ajusta sua posição em rlação à parede com base na distância lida pelo sonar 0. */
	while(read_sonar(sonar) < limiar){
		set_motors_speed(&motor_esquerda, &motor_direita);
		for(i = 0; i < 5000000; i++){
		} 	
	}
	anda_reto();

	return;
}