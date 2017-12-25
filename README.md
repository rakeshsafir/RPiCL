# RPiCL
Creating GPU accelerated OpenCL dev environment

This utility script downloads OpenCL-ICD loader from Khronos and cross compiles it for RPi using the 
broadcom toolchain for RPi.

Additionally it downloads and extracts the compiled binaries from the CI servers of doe300 for the 
OpenCL implementation and creates a sysroot for the same. This should enable anyone to create 
OpenCL based applications for RPi. 

# references
Inspired by the great work of: https://github.com/doe300


. Build
after cloning 
./build.sh to download and compile OpenCL-ICD loader

