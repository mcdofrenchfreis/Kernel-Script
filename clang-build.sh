#!/usr/bin/env bash
#
# Build Script for Biofrost Kramel [CLANG]
# Copyright (C) 2022-2023 Mar Yvan D.
#

# MMDA Clearing Operation (anti re-send)
echo "Clearing Environment"
rm -rf $(pwd)/AnyKernel/*.zip
echo "Nuking DTB and DTBO in AK3 Folder"
rm -rf $(pwd)/AnyKernel/Image.gz-dtb && rm -rf $(pwd)/AnyKernel/dtbo.img
echo "Nuking out Folder"
rm -rf $(pwd)/out
echo "Cleaning Completed."

# Toolchain link is only needed for CI Purposes.
echo "Cloning Toolchain | Compiler (Clang)"
git clone --depth=1 https://github.com/kdrag0n/proton-clang.git clang
echo "Cloning AnyKernel3"
git clone --depth=1 https://github.com/mcdofrenchfreis/AnyKernel3.git -b biofrost AnyKernel
echo "Cloning Dependencies Done!"

# GitHub Repository Link.
export REPO_URL="https://github.com/mcdofrenchfreis/biofrost-oss-r5x"

# Default kernel directory.
KDIR=$(pwd)

# Main
DTBO=${KDIR}/out/arch/arm64/boot/dtbo.img
IMAGE=${KDIR}/out/arch/arm64/boot/Image.gz-dtb
DATE=$(TZ=Asia/Singapore date +"%Y%m%d-%s")
START=$(date +"%s")
export ARCH=arm64

# Default compiler directory.
TCDIR=${KDIR}/clang

# Maintainer and Host Information.
export KBUILD_BUILD_USER="xevan"
export KBUILD_BUILD_HOST=ArchLinux

# Compiler + Linker information.
export COMPILER_NAME="$(${TCDIR}/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export LINKER_NAME="$("${TCDIR}"/bin/ld.bfd --version | head -n 1 | sed 's/(compatible with [^)]*)//' | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

# Device name.
export DEVICE="Realme 5 Series"

# Kernel Version
export VERSION="R0406"

# Device codename.
export CODENAME="realme_trinket"

# Top Commit Information (commit hash).
export COMMIT_HASH=$(git rev-parse --short HEAD)

# Default device defconfig used.
DEVICE_DEFCONFIG=biofrost_defconfig

# Telegram Bot Information.
bot_token="bot5129489057:AAF5o-JfQ1iAUp9Min7Jcr9sHPjTpCaIlA8"

# Where to push? Set 1 for Group, 0 for Personal
TESTING_GROUP=0
if [ "${TESTING_GROUP}" = 1 ]; then
    chat_id="-1001736789494"
else
    chat_id="-1001525610478"
fi

# Zip Details
export ZIP_NAME="Biofrost-${VERSION}-${DATE}"

# Post Main Information
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/$bot_token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b> - Biofrost Laboratory | Machine Build Triggered</b>%0A<b>Maintainer: </b><code>${KBUILD_BUILD_USER}</code>%0A<b>Build Date: </b><code>$(date +"%Y-%m-%d %H:%M")</code>%0A<b>Device: </b><code>${DEVICE} (${CODENAME})</code>%0A<b>Kernel Version: </b><code>$(make kernelversion 2>/dev/null)</code>%0A<b>Compiler: </b><code>${COMPILER_NAME}</code>%0A<b>Linker: </b><code>${LINKER_NAME}</code>%0A<b>Zip Name: </b><code>${ZIP_NAME}</code>%0A<b>Branch: </b><code>$(git rev-parse --abbrev-ref HEAD)</code><code>(master)</code>%0A<b>Last Commit Details: </b><a href='${REPO_URL}/commit/${COMMIT_HASH}'>${COMMIT_HASH}</a> <code>($(git log --pretty=format:'%s' -1))</code>"
}   
# Push Build to Channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/$bot_token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds. | <b>Compiled with: ${COMPILER_NAME}+ ${LINKER_NAME}.</b>"
}
# Error? Press F
function finerr() {
    curl -s -X POST "https://api.telegram.org/$bot_token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="Compilation failed, please check build logs for errors."
    exit 1
}
# Compile >.<
function compile() {
    make O=out ARCH=arm64 ${DEVICE_DEFCONFIG}
    make -j$(nproc --all) O=out \
              PATH=${TCDIR}/bin/:${PATH} \
              ARCH=arm64 \
			  CC=clang \
			  CROSS_COMPILE=aarch64-linux-gnu- \
			  CROSS_COMPILE_ARM32=arm-linux-gnueabi- 
		      AR=llvm-ar \
              AS=llvm-as \
			  OBJDUMP=llvm-objdump \
			  STRIP=llvm-strip \
			  NM=llvm-nm \
			  OBJCOPY=llvm-objcopy \

    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel

    if ! [ -a "$DTBO" ]; then
        finerr
        exit 1
    fi
    cp out/arch/arm64/boot/dtbo.img AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 ${ZIP_NAME}.zip *
    cd ..
}
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
