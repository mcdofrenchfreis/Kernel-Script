#!/usr/bin/env bash

echo "Select an option:"
echo "1. Completely regenerate defconfig"
echo "2. Commit defconfig only"
echo "3. Run menuconfig"
read -p "Enter your choice (1/2/3): " choice

case $choice in
  1)
    export PATH="/home/biofrost/Development/Compiler/AndroidClang/bin:${PATH}"
    make ARCH=arm64 CC=clang biofrost_defconfig
    cp .config arch/arm64/configs/biofrost_defconfig
    git add arch/arm64/configs/biofrost_defconfig
    git commit -m "biofrost_defconfig: regen"
    ;;
  2)
    git add arch/arm64/configs/biofrost_defconfig
    git commit -m "biofrost_defconfig: regen"
    ;;
  3)
    export ARCH=arm64
    make biofrost_defconfig
    make menuconfig
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

