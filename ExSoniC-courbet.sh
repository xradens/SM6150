#!/bin/bash
#
# Script For Building Android arm64 Kernel
#
# Copyright (C) 2021-2024 Lek_N-XIV <exsonic14@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Setup colour for the script
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'

# Deleting out "kernel complied" and zip "anykernel" from an old compilation
echo -e "$green << cleanup >> \n $white"

rm -rf out
rm -rf zip
rm -rf error.log

echo -e "$green << setup dirs >> \n $white"

# With that setup , the script will set dirs and few important thinks

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

export CHATID API_BOT TYPE_KERNEL

# Kernel build config
TYPE="MIUI"
DEVICE_CODENAME="COURBET"
DEVICE="MI11LITE"
KERNEL_NAME="ExSoniC-perf"
DEFCONFIG="courbet_defconfig"
AnyKernel="https://github.com/SoniC-XIV/Anykernel3"
AnyKernelbranch="sweet"
HOSST="Lek_N-XIV"
USEER="ASM-26"
ID="26"

# clang config
REMOTE="https://gitlab.com"
TARGET="PixelOS-Devices"
REPO="playgroundtc"
BRANCH="17"

# setup telegram env
export WAKTU=$(date +"%T")
export TGL=$(date +"%d-%m-%Y_%S")
export BOT_MSG_URL="https://api.telegram.org/bot$API_BOT/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot$API_BOT/sendDocument"

# clang stuff
		echo -e "$green << cloning clang >> \n $white"
		git clone --depth=1 -b "$BRANCH" "$REMOTE"/"$TARGET"/"$REPO" "$HOME"/clang
		#git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git "$HOME"/clang/aarch64-linux-android-4.9
		#git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git "$HOME"/clang/arm-linux-androideabi-4.9

	export PATH="$HOME/clang/bin:$PATH"
	export KBUILD_COMPILER_STRING=$("$HOME"/clang/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')

tg_sticker() {
   curl -s -X POST "https://api.telegram.org/bot$API_BOT/sendSticker" \
        -d sticker="$1" \
        -d chat_id=$CHATID
}

tg_post_msg() {
        curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" \
        -d "parse_mode=markdown" \
        -d text="$1"
}

tg_post_build() {
        #Post MD5Checksum alongwith for easeness
        MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

        #Show the Checksum alongwith caption
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$2" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=markdown" \
        -F caption="$3✅ 😉 MD5 \`$MD5CHECK\`"
}

tg_error() {
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$2" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$3❌ 😥 Failed to build , check <code>error.log</code>❗"
}

# Setup build process

build_kernel() {
Start=$(date +"%s")
	  make -j$(nproc --all) O=out \
	                          ARCH=arm64 \
                              CC=clang \
                              AR=llvm-ar \
                              NM=llvm-nm \
                              OBJCOPY=llvm-objcopy \
                              OBJDUMP=llvm-objdump \
                              STRIP=llvm-strip \
                              LD=ld.lld \
                              CROSS_COMPILE=aarch64-linux-gnu- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                              LLVM=1 \
                              LLVM_IAS=1 \
                              2>&1 | tee error.log
End=$(date +"%s")
Diff=$(($End - $Start))
}

# Let's start
echo -e "$green << doing pre-compilation process >> \n $white"
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64
export KBUILD_BUILD_HOST="$HOSST"
export KBUILD_BUILD_USER="$USEER"
export KBUILD_BUILD_VERSION="$ID"

mkdir -p out

make O=out clean && make O=out mrproper
make "$DEFCONFIG" O=out

echo -e "$yellow << compiling the kernel >> \n $white"

# stiker post


build_kernel || error=true

DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)

export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz
export dtbo="$MY_DIR"/out/arch/arm64/boot/dtbo.img
export dtb="$MY_DIR"/out/arch/arm64/boot/dtb.img


        if [ -f "$IMG" ]; then
                echo -e "$green << selesai dalam $(($Diff / 60)) menit and $(($Diff % 60)) detik >> \n $white"
        else
                echo -e "$red << Gagal dalam membangun kernel!!! , cek kembali kode anda >>$white"
                tg_post_msg "GAGAL!!! uploading log"
                tg_error "error.log" "$CHATID"
                tg_post_msg "done" "$CHATID"
                rm -rf out
                rm -rf testing.log
                rm -rf error.log
                exit 1
        fi

TEXT1="
* Build Completed Successfully*
* Device* : \`$DEVICE\`
* Code name* : \`Sweet | Sweetin\`
* Variant Build* : \`$TYPE\`
* Time Build* : \`$(($Diff / 60)) menit\`
* Date Build* : \`$TGL\` \`$WAKTU\`
"

        if [ -f "$IMG" ]; then
                echo -e "$green << cloning AnyKernel from your repo >> \n $white"
                git clone --depth=1 "$AnyKernel" --single-branch -b "$AnyKernelbranch" zip
                echo -e "$yellow << making kernel zip >> \n $white"
                cp -r "$IMG" zip/
                cp -r "$dtbo" zip/
                cp -r "$dtb" zip/
                cd zip
                export ZIP="$KERNEL_NAME"-"$TYPE"-"$TGL"
                zip -r9 "$ZIP" * -x .git README.md LICENSE *placeholder
                curl -sLo zipsigner-3.0.jar https://github.com/Magisk-Modules-Repo/zipsigner/raw/master/bin/zipsigner-3.0-dexed.jar
                java -jar zipsigner-3.0.jar "$ZIP".zip "$ZIP"-signed.zip
                tg_sticker "CAACAgUAAxkBAAGLlS1jnv1FJAsPoU7-iyZf75TIIbD0MQACYQIAAvlQCFTxT3DFijW-FSwE"
                tg_post_msg "$TEXT1" "$CHATID"
                tg_post_build "$ZIP"-signed.zip "$CHATID"
                cd ..
                rm -rf error.log
                rm -rf out
                rm -rf zip
                rm -rf testing.log
                exit
        fi
