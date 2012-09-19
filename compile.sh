#!/bin/bash

# create the directory
mkdir bin

# compile
fpc src/main.pas -O2 -Xs -Cg -FEbin -ocalculator

# remove crap
cd bin
rm *.o *.ppu
