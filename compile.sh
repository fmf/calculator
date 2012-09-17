#!/bin/bash

# create the directory
mkdir release

# compile
fpc src/main.pas -O2 -Xs -Cg -FErelease -ocalculator

# remove crap
cd release
rm *.o *.ppu
