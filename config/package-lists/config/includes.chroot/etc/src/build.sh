#!/bin/bash
set -e

# 1. Собираем утилиту на ассемблере
nasm -f elf64 src/cpupass.asm -o cpupass.o
ld cpupass.o -o cpupass
mkdir -p config/includes.chroot/usr/local/bin
cp cpupass config/includes.chroot/usr/local/bin/
chmod +x config/includes.chroot/usr/local/bin/cpupass

# 2. Настраиваем live-build
lb config --distribution bookworm --architectures amd64 \
          --binary-images iso-hybrid \
          --bootappend-live "boot=live components" \
          --iso-application "DiagOS" --iso-volume "DiagOS"

# 3. Собираем ISO
lb build
