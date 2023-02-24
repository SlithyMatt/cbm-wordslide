#!/bin/sh

gcc -o wordtable.exe wordtable.c

./wordtable.exe 2500words.txt
cp WORDS.BIN words.bin

cl65 -t cx16 -l x16-wordslide.list -o WSX16.PRG wordslide.asm
cl65 -t c64 -l c64-wordslide.list -o wsc64 wordslide.asm
cl65 -t vic20 -C vic20-cart-main.cfg -l vic20-wordslide.list -o wsvic20_a.crt wordslide.asm
dd if=/dev/zero bs=1 count=8194 > wsvic20_2.crt
dd if=WORDS.BIN of=wsvic20_2.crt conv=notrunc
