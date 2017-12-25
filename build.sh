#!/bin/bash

echo "Script to add OpenCL-1.2 support to broadcom RPi toolchain..."

BASE=$(pwd)
SYSROOT=$BASE/sysroot
RPI_BASE=$BASE/RPi
mkdir -p $SYSROOT
mkdir -p $RPI_BASE

github_get() 
{
	if test ! -d $2; then
		echo "git clone -b $3 https://github.com/$1/$2.git $4"
		git clone -b $3 https://github.com/$1/$2.git $4
		return $?
	else
		echo "Skipping download [github]:[$3]:$2..."
		return 0
	fi
}


# Download RPi firmware and tools
rpi_pre_reqs()
{
	cd $BASE/RPi
	github_get raspberrypi tools master tools
	github_get raspberrypi firmware master firmware 
}

# Download and Compile OpenCL-ICD-Loader for RPi
create_rpi_icd_loader()
{
	cd $BASE
	github_get KhronosGroup OpenCL-ICD-Loader master icd-loader
	github_get KhronosGroup OpenCL-Headers master ocl-headers
	cd $BASE/icd-loader/inc
	cp -rf $BASE/ocl-headers/opencl12/CL .
	cd ..
	git am -3 '../0001-reverting-icd-loader-to-opencl-1.2.patch'
	git am -3 '../0002-enabling-cross-compilation-of-icd-loader-for-RPi.patch'
	mkdir -p build && cd build
	cmake .. -DCROSS_COMPILE=ON -DCROSS_COMPILER_PATH=$RPI_BASE/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64 -DOPENGLES_INCLUDE_DIRS=$RPI_BASE/firmware/opt/vc/include
	make && make install	
}

# HACK:TODO: get precompiled binaries for now will replace with compilation from source
hack_get_prebuilt()
{
	cd $BASE
	echo "Downloading compiled .deb for VC4CL"
	curl "https://circleci.com/api/v1.1/project/github/doe300/VC4CL/latest/artifacts?branch=master&filter=successful" --output $BASE/dump-1
	wget -O $BASE/vc4cl-0.4-Linux.deb $(python $BASE/get_url.py "vc4cl-" "$BASE/dump-1")

	echo "Transfer vc4cl-0.4-Linux.deb on RPi and install via"
	echo "    dpkg -i vc4cl-0.4-Linux.deb"

	echo "Setting up the cross toolchain..."
	curl "https://circleci.com/api/v1.1/project/github/doe300/VC4C/latest/artifacts?branch=master&filter=successful" --output $BASE/dump-2
	wget -O $BASE/vc4cl-stdlib.deb $(python $BASE/get_url.py "vc4cl-stdlib-" "$BASE/dump-2")
	wget -O $BASE/vc4c.deb $(python $BASE/get_url.py "vc4c-" "$BASE/dump-2")

	dpkg-deb -x $BASE/vc4cl-stdlib.deb $RPI_BASE/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/arm-linux-gnueabihf/ 
	dpkg-deb -x $BASE/vc4c.deb $RPI_BASE/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/arm-linux-gnueabihf/
	dpkg-deb -x $BASE/vc4cl-0.4-Linux.deb $RPI_BASE/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/arm-linux-gnueabihf/
	
	dpkg-deb -x $BASE/vc4cl-0.4-Linux.deb $SYSROOT
	rm -f $BASE/dump-1 $BASE/dump-2 $BASE/vc4cl-stdlib.deb $BASE/vc4c.deb $BASE/vc4cl-0.4-Linux.deb
}


enable_ocl_toolchain() 
{
	rpi_pre_reqs
	create_rpi_icd_loader
	hack_get_prebuilt
}

enable_ocl_toolchain

echo "Cross Compiler Flags..."
echo "CROSS_COMPILE_PREFIX  :=$RPI_BASE/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-"
echo "CFLAGS                +=-I$RPI_BASE/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/arm-linux-gnueabihf/usr/local/include"
echo "LDFLAGS               +=-L$RPI_BASE/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/arm-linux-gnueabihf/usr/local/lib"
echo "LIBS                  +=-lOpenCL"

