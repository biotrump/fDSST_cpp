#!/bin/bash

#export CMAKE_BUILD_TYPE="Debug"
export CMAKE_BUILD_TYPE="Release"

while [ $# -ge 1 ]; do
	case $1 in
	-ABI|-abi)
		echo "\$1=-abi"
		shift
		APP_ABI=$1
		shift
		;;
	-clean|-c|-C) #
		echo "\$1=-c,-C,-clean"
		clean_build=1
		shift
		;;
	-l|-L)
		echo "\$1=-l,-L"
		local_build=1
		;;
	--help|-h|-H)
		# The main case statement will give a usage message.
		echo "$0 -c|-clean -abi=[armeabi, armeabi-v7a, armv8-64,mips,mips64el, x86,x86_64]"
		exit 1
		break
		;;
	-*)
		echo "$0: unrecognized option $1" >&2
		exit 1
		;;
	*)
		break
		;;
	esac
done
echo APP_ABI=$APP_ABI
export APP_ABI

#https://developer.android.com/about/dashboards/index.html
#AND4.4	KitKat		API LEVEL 19
#AND5.0	Lollipop	API LEVEL 21
#AND5.1	Lollipop	API LEVEL 22
#AND6.0	Marshmallow	API LEVEL 23
#AND7.0	Nougat		API LEVEL 24

if [ -z "${NDK_ROOT_FORTRAN}"  ]; then
	export NDK_ROOT_FORTRAN=${HOME}/NDK/android-ndk-r12b
fi

if [ -z "${NDK_ROOT}"  ]; then
	export NDK_ROOT=${HOME}/NDK/android-ndk-r12b
fi
export ANDROID_NDK=${NDK_ROOT}

if [[ ${NDK_ROOT} =~ .*"-r9".* ]]
then
	ANDROID_APIVER=android-14
	TOOL_VER="4.8.0"
else
	#r10e : 21 android 4.4 kitkat, 14 : 4.0.4
	if [ "$APP_ABI" = "arm64-v8a" -o \
		"$APP_ABI" = "x86_64" -o \
		"$APP_ABI" = "mips64" ]; then
		ANDROID_APIVER=android-21
		TOOL_VER="4.9"
	else
#http://stackoverflow.com/questions/36746904/android-linker-undefined-reference-to-bsd-signal
#backward compatible issue,32bit lib has bsd_signal only before API19, kitkat
		ANDROID_APIVER=android-21
		TOOL_VER="4.9"
	fi
fi

case $(uname -s) in
  Darwin)
    CONFBUILD=i386-apple-darwin`uname -r`
    HOSTPLAT=darwin-x86
    CORE_COUNT=`sysctl -n hw.ncpu`
  ;;
  Linux)
    CONFBUILD=x86-unknown-linux
    HOSTPLAT=linux-`uname -m`
    CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
  ;;
CYGWIN*)
	CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
	;;
  *) echo $0: Unknown platform; exit
esac

#default is arm
#export PATH="$NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin/:\
#$NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/${TARGPLAT}/bin/:$PATH"
case $APP_ABI in
  armeabi)
    TARGPLAT=arm-linux-androideabi
    TOOLCHAINS=arm-linux-androideabi
    ARCH=arm

	#FFTS_LIB_NAME=ffts
	PICORT_LIB_NAME=picort
	FFTE_LIB_NAME=ffte
	NUFFT_LIB_NAME=nufft
	COLORSPACE_LIB_NAME=colorspace
	LIBYUV_NAME=yuv-static
	FFTPACK_LIB_NAME=fftbase
	#libpico-NDK-arm.a
	#enable VFP only
  ;;
  armeabi-v7a)
    TARGPLAT=arm-linux-androideabi
    TOOLCHAINS=arm-linux-androideabi
    ARCH=arm
	#enable NEON
	#FFTS_LIB_NAME=ffts
	#FFTE_LIB_NAME=ffte_vec
	PICORT_LIB_NAME=picort
	FFTE_LIB_NAME=ffte
	NUFFT_LIB_NAME=nufft
	COLORSPACE_LIB_NAME=colorspace
	LIBYUV_NAME=yuv-static
	FFTPACK_LIB_NAME=fftbase
  ;;
  arm64-v8a)
    TARGPLAT=aarch64-linux-android
    TOOLCHAINS=aarch64-linux-android
    ARCH=arm64
	#FFTS_LIB_NAME=ffts
	#FFTE_LIB_NAME=ffte_vec
	PICORT_LIB_NAME=picort
	FFTE_LIB_NAME=ffte
	NUFFT_LIB_NAME=nufft
	COLORSPACE_LIB_NAME=colorspace
	LIBYUV_NAME=yuv-static
	FFTPACK_LIB_NAME=fftbase
  ;;
  x86)
    TARGPLAT=i686-linux-android
    TOOLCHAINS=x86
    ARCH=x86
	#specify assembler for x86 SSE3, but ffts's sse.s needs 64bit x86.
	#intel atom z2xxx and the old atoms are 32bit
	#http://forum.cvapp.org/viewtopic.php?f=13&t=423&sid=4c47343b1de899f9e1b0d157d04d0af1
	export  CCAS="${TARGPLAT}-as"
	export  CCASFLAGS="--32 -march=i686+sse3"
	PICORT_LIB_NAME=picort
	#FFTE_LIB_NAME=ffte_vec
	#FFTS_LIB_NAME=ffts
	FFTE_LIB_NAME=ffte
	NUFFT_LIB_NAME=nufft
	COLORSPACE_LIB_NAME=colorspace
	LIBYUV_NAME=yuv-static
	FFTPACK_LIB_NAME=fftbase

  ;;
  x86_64)
    TARGPLAT=x86_64-linux-android
    TOOLCHAINS=x86_64
    ARCH=x86_64
    #specify assembler for x86 SSE3, but ffts's sse.s needs 64bit x86.
	#atom-64 or x86-64 devices only.
	#http://forum.cvapp.org/viewtopic.php?f=13&t=423&sid=4c47343b1de899f9e1b0d157d04d0af1
	export  CCAS="${TARGPLAT}-as"
#	export  CCASFLAGS="--64 -march=i686+sse3"
	export  CCASFLAGS="--64"
	PICORT_LIB_NAME=picort
	#FFTS_LIB_NAME=ffts
	#FFTE_LIB_NAME=ffte_vec
	FFTE_LIB_NAME=ffte
	NUFFT_LIB_NAME=nufft
	COLORSPACE_LIB_NAME=colorspace
	LIBYUV_NAME=yuv-static
	FFTPACK_LIB_NAME=fftbase
  ;;
  mips)
	TARGPLAT=mipsel-linux-android
	TOOLCHAINS=mipsel-linux-android
	ARCH=mips
	PICORT_LIB_NAME=picort
	#FFTS_LIB_NAME=ffts
	FFTE_LIB_NAME=ffte
	NUFFT_LIB_NAME=nufft
	COLORSPACE_LIB_NAME=colorspace
	LIBYUV_NAME=yuv-static
	FFTPACK_LIB_NAME=fftbase
  ;;
  mips64)
	TARGPLAT=mips64el-linux-android
	TOOLCHAINS=mips64el-linux-android
	ARCH=mips64
	PICORT_LIB_NAME=picort
	#FFTS_LIB_NAME=ffts
	FFTE_LIB_NAME=ffte
	NUFFT_LIB_NAME=nufft
	COLORSPACE_LIB_NAME=colorspace
	LIBYUV_NAME=yuv-static
	FFTPACK_LIB_NAME=fftbase
  ;;
  *) echo $0: Unknown target; exit
esac

export SYS_ROOT="${NDK_ROOT}/platforms/${ANDROID_APIVER}/arch-${APP_ABI}/"
export CC="${TARGPLAT}-gcc --sysroot=$SYS_ROOT"
export LD="${TARGPLAT}-ld"
export AR="${TARGPLAT}-ar"
export ARCH=${AR}
export RANLIB="${TARGPLAT}-ranlib"
export STRIP="${TARGPLAT}-strip"
#export CFLAGS="-Os -fPIE"
export CFLAGS="-Os -fPIE -fPIC --sysroot=$SYS_ROOT"
export CXXFLAGS="-fPIE -fPIC --sysroot=$SYS_ROOT"
export FORTRAN="${TARGPLAT}-gfortran --sysroot=$SYS_ROOT"

#!!! quite importnat for cmake to define the NDK's fortran compiler.!!!
#Don't let cmake decide it.
export FC=${FORTRAN}

#include path :
#platforms/android-21/arch-arm/usr/include/
if [ -z "$KCF_DIR" ]; then
	export KCF_DIR=${KCF_DIR:-${CV_HOME}/cf_tracking}
fi

if [ -z "$KCF_OUT" ]; then
	export KCF_OUT=${KCF_OUT:-${CV_OUT}/cf_tracking}
fi

if [ -d "$KCF_OUT/$APP_ABI" ]; then
	rm -rf $KCF_OUT/$APP_ABI/*
else
	mkdir -p $KCF_OUT/$APP_ABI
fi

pushd ${KCF_OUT}/$APP_ABI
pwd
#read
#echo ANDROID_TOOLCHAIN_NAME=${TOOLCHAINS}-${TOOL_VER}
#read

case $APP_ABI in
  armeabi-v7a)
		cmake -DCMAKE_TOOLCHAIN_FILE=${KCF_DIR}/android.toolchain.cmake \
		-DANDROID_NATIVE_API_LEVEL=${ANDROID_APIVER} \
		-DANDROID_NDK=${ANDROID_NDK} -DANDROID_TOOLCHAIN_NAME=${TOOLCHAINS}-${TOOL_VER} \
		-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DANDROID_ABI="armeabi-v7a with NEON" -DAPP_ABI=$APP_ABI \
		${KCF_DIR}
	;;
  arm64-v8a)
		cmake -DCMAKE_TOOLCHAIN_FILE=${KCF_DIR}/android.toolchain.cmake \
		-DANDROID_NATIVE_API_LEVEL=${ANDROID_APIVER} \
		-DANDROID_NDK=${ANDROID_NDK} -DANDROID_TOOLCHAIN_NAME=${TOOLCHAINS}-${TOOL_VER} \
		-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DANDROID_ABI="arm64-v8a" -DAPP_ABI=$APP_ABI \
		${KCF_DIR}
	;;
  x86)
		cmake -DCMAKE_TOOLCHAIN_FILE=${KCF_DIR}/android.toolchain.cmake \
		-DANDROID_NATIVE_API_LEVEL=${ANDROID_APIVER} \
		-DANDROID_NDK=${ANDROID_NDK} -DANDROID_TOOLCHAIN_NAME=${TOOLCHAINS}-${TOOL_VER} \
		-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DANDROID_ABI="x86" -DAPP_ABI=$APP_ABI \
		${KCF_DIR}
	;;
  x86_64)
		cmake -DCMAKE_TOOLCHAIN_FILE=${KCF_DIR}/android.toolchain.cmake \
		-DANDROID_NATIVE_API_LEVEL=${ANDROID_APIVER} \
		-DANDROID_NDK=${ANDROID_NDK} -DANDROID_TOOLCHAIN_NAME=${TOOLCHAINS}-${TOOL_VER} \
		-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DANDROID_ABI="x86_64" -DAPP_ABI=$APP_ABI \
		${KCF_DIR}
	;;
  mips64)
		cmake -DCMAKE_TOOLCHAIN_FILE=${KCF_DIR}/android.toolchain.cmake \
		-DANDROID_NATIVE_API_LEVEL=${ANDROID_APIVER} \
		-DANDROID_NDK=${ANDROID_NDK} -DANDROID_TOOLCHAIN_NAME=${TOOLCHAINS}-${TOOL_VER} \
		-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DANDROID_ABI="mips64" -DAPP_ABI=$APP_ABI \
		${KCF_DIR}
	;;
  *) echo $0: Unknown target; exit
esac
ls -l

ret=$?
echo "ret=$ret"
if [ "$ret" != '0' ]; then
echo "$0 cmake error!!!!"
exit -1
fi

make -j${CORE_COUNT}
ret=$?
echo "ret=$ret"
if [ "$ret" != '0' ]; then
echo "$0 make error!!!!"
exit -1
fi

pushd ${KCF_OUT}
mkdir -p libs/$APP_ABI
rm -rf libs/$APP_ABI/*
ln -s ${KCF_OUT}/$APP_ABI/lib/libKCF.a ${KCF_OUT}/libs/$APP_ABI/libKCF.a
ln -s ${KCF_OUT}/$APP_ABI/lib/libKCFC.a ${KCF_OUT}/libs/$APP_ABI/libKCFC.a
popd
exit 0

