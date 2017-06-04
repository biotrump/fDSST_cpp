#!/bin/bash
#Thomas Tsai <thomas@biotrump.com>
#export CMAKE_BUILD_TYPE "Debug"
export CMAKE_BUILD_TYPE="Release"

if [ -z "$KCF_DIR" ]; then
	export KCF_DIR=${KCF_DIR:-`pwd`}
fi

if [ -z "$KCF_OUT" ]; then
	export KCF_OUT=${KCF_OUT:-$CV_OUT/kcf}
fi

#clean build
if [ -d $KCF_OUT/$TARGET_ARCH ]; then
	rm -rf $KCF_OUT/$TARGET_ARCH/*
else
	mkdir -p $KCF_OUT/$TARGET_ARCH
fi

pushd ${KCF_OUT}/$TARGET_ARCH
cmake -DTARGET_ARCH=${TARGET_ARCH} \
${KCF_DIR}

ret=$?
echo "ret=$ret"
if [ "$ret" != '0' ]; then
echo "$0 cmake error!!!!"
exit -1
fi

make ${MAKE_FLAGS}

ret=$?
echo "ret=$ret"
if [ "$ret" != '0' ]; then
echo "$0 make error!!!!"
exit -1
fi

popd

pushd ${KCF_OUT}
mkdir -p libs/$TARGET_ARCH
rm -rf libs/$TARGET_ARCH/*
ln -s ${KCF_OUT}/$TARGET_ARCH/lib/libKCF.a ${KCF_OUT}/libs/$TARGET_ARCH/libKCF.a
ln -s ${KCF_OUT}/$TARGET_ARCH/lib/libKCFC.a ${KCF_OUT}/libs/$TARGET_ARCH/libKCFC.a
popd

