#!/bin/bash
set -x

toolchain_path=$1
devkit_path=$2
c_app_path=$3
cpp_app_path=$4
pthread_app_path=$5
cmake_app_path=$6

# Cleanup temp directory
function finish {
	if [ -n $tmpdir ]; then
		rm -rf $tmpdir
	fi
}
trap finish EXIT

export PATH=$toolchain_path:$PATH
tmpdir=$(mktemp -d)

# Install devkit
cd $tmpdir
wget --no-proxy $devkit_path || exit 1
devkit=$(ls)
chmod +x $devkit
yes Y | ./$devkit
cd Y
source ./environment-setup || exit 1

# Test c compilation
$CC $c_app_path -o hello || exit 1
file hello | grep ARM || exit 1

# Test c++ compilation
$CXX $cpp_app_path -o hello || exit 1
file hello | grep ARM || exit 1

# Test compilation with pthread library
$CC $pthread_app_path -o thread-ex -lpthread || exit 1
file thread-ex | grep ARM || exit 1

# Test gstreamer compilation
wget --no-check-certificate https://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-1.2.0.tar.xz || exit 1
tar xf gst-plugins-good-1.2.0.tar.xz  || exit 1
cd gst-plugins-good-1.2.0/ || exit 1
./configure --host=i686 --disable-deinterlace --disable-goom  || exit 1
make  || exit 1

# Test cmake compilation
cd $cmake_app_path || exit 1
cmake . || exit 1
make || exit 1
file Tutorial | grep ARM || exit 1


echo "All host-side devkit checks passed"
exit 0