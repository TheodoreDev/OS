#!/bin/bash

make clean
make OS
echo "TedOS is starting ..."
qemu-system-i386 -k fr -fda OS.bin
