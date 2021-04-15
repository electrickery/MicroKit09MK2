MicroKit09 and MicroKit09_OI are the CPU and I/O (display, keyboard & 
cassette interface) boards.

The main differences from the 1980's original are:
* the form factor, 
* inter-board connector, 
* display type,
* keyboard construction,
* expansion connector (most pins use the 6809 pinout),
* ROM-size jumper (2 kByte / 4 kByte),
* RAM size jumper (2 kByte / 8 kByte),
* controllable LED on CPU-board (connects to PIA-CB2, also cassette out),
* added more address decoding for the I/O segment at A000h, reducing the
  memory range of the PIA to 1 kByte (was 8 kByte). A chip-select signal
  for A400h-A7FFh is available on the expansion connector.

MicroKit09Serial is the (as yet) untested serial interface. 
