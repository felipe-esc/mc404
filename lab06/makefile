ra171043.o: ra171043.s
	arm-eabi-as ra171043.s -o ra171043.o
	arm-eabi-ld ra171043.o -o ra171043 -Ttext=0x77802000 -Tdata=0x77803000
disk.img:
	mksd.sh --so /home/specg12-1/mc404/simulador/dummyos.elf --user ra171043
clean:
	rm -f ra171043.o ra171043 disk.img
