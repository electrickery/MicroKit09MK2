#!/bin/sh
#

EXE=/home/fjkraan/kryten/Programming/crossasm/asm6809/src/asm6809

BASE=`echo $1 | sed -e 's/\.asm$//'`

echo $BASE

$EXE -S -o $BASE.s19 -l $BASE.lst -v $1 
$EXE -B -o $BASE.bin -l $BASE.lst -v $1 



#Usage: asm6809 [OPTION]... SOURCE-FILE...
#Assembles 6809/6309 source code.
#
#  -B, --bin         output to binary file (default)
#  -D, --dragondos   output to DragonDOS binary file
#  -C, --coco        output to CoCo segmented binary file
#  -S, --srec        output to Motorola SREC file
#  -H, --hex         output to Intel hex record file
#  -e, --exec=ADDR   EXEC address (for output formats that support one)
#
#  -8,
#  -9, --6809                  use 6809 ISA (default)
#  -3, --6309                  use 6309 ISA (6809 with extensions)
#  -d, --define=SYM[=NUMBER]   define a symbol
#      --setdp=VALUE           initial value assumed for DP [undefined]
#
#  -o, --output=FILE    set output filename
#  -l, --listing=FILE   create listing file
#  -E, --exports=FILE   create exports table
#  -s, --symbols=FILE   create symbol table
#
#  -q, --quiet     don't warn about illegal (but working) code
#  -v, --verbose   warn about explicitly inefficient code
#
#      --help      show this help
#      --version   show program version
