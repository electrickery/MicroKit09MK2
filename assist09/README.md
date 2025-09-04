* ASSIST09 on the MicroKit09MK2

ASSIST09 as configured in this directory requires RAM at $0000 to $1FFF, ROM at $E000-$FFFF and an ACIA (MC6850) at $A400-$A401. 

For the trace function, a PMT (MC6840) at $A800-$A807 is needed, with the output of Timer1 (pin 27) connected to the NMI input of the processor.

There is no custom schematic (yet), but it is a combination of the MicroKit09MK2-CPU board and the MicroKit09MK2 Serial/Timer board.

fjkraan@electrickery.nl, 2025-09-04
