motors.o: motors.s
	arm-eabi-as motors.s -o motors.o
	arm-eabi-ld motors.o -o motors  -Ttext=0x77802000
disk.img: motors
	mksd.sh --so /home/specg12-1/mc404/simulador/simulador_player/bin/knrl --user motors
clean:
	rm -f motors.o motors disk.img
