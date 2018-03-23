ra171043:
	arm-eabi-as -g ra171043.s -o ra171043.o
	arm-eabi-ld ra171043.o -o ra171043 -g --section-start=.iv=0x778005e0 -Ttext=0x77800700 -Tdata=0x77801800 -e 0x778005e0
disk.img: ra171043 
	mksd.sh --so ra171043 --user faz_nada
clean:
	rm -f 171043.o ra171043 disk.img
