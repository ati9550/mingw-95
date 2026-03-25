#!/bin/bash
# build.sh - script compiling the toolchain
# Copyright (C) 2026 ati9550
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# download

if [ ! -f "download_success.log" ]; then
	rm -r src
	rm -r mingw-w64
	rm -r binutils-*
	rm -r gcc-*
	rm -r libunicows-*

	set -e

	mkdir src
	cd src
	# wget https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz &&   # their ftp is
	# wget https://ftp.gnu.org/gnu/gcc/gcc-12.5.0/gcc-12.5.0.tar.xz &&# not reliable
	wget https://mirror.truenetwork.ru/gnu/binutils/binutils-2.42.tar.xz
	wget https://mirror.truenetwork.ru/gnu/gcc/gcc-12.5.0/gcc-12.5.0.tar.xz
	wget https://prdownloads.sourceforge.net/libunicows/libunicows-1.1.1-mingw32.zip
	cd ..
	tar -xf src/binutils-*.tar.xz
	tar -xf src/gcc-*.tar.xz
	unzip src/libunicows-*.zip

	git clone https://github.com/mingw-w64/mingw-w64.git
	cd mingw-w64
	git checkout v13.0.0
	cd ..

	cd gcc-*
	patch -p1 < ../fix-gcc-win95-interlock-compare-exchange.patch
	patch -p1 < ../fix-gcc-disable-quick-exit.patch
	cd ..

	set +e
	echo 1 > download_success.log
fi

# target dir

set +e
rm -r build

set -e
mkdir build
export PREFIX="$PWD/build"
export TARGET=i586-w64-mingw32
export TARGET_FOR_MINGW=i686-w64-mingw32 # it will not accept i586

# clean

set +e

rm -r build-*/
export OLDPWD="$PWD"

cd mingw-w64/mingw-w64-headers &&
make clean
cd "$OLDPWD"

cd mingw-w64/mingw-w64-crt &&
make clean
cd "$OLDPWD"

# binutils

mkdir build-binutils
cd build-binutils

../binutils-*/configure \
 --target="$TARGET" \
 --prefix="$PREFIX" \
 --disable-multilib

make -j$(nproc)
make install
cd ..

# mingw-w64-headers

cd mingw-w64/mingw-w64-headers

./configure \
 --host="$TARGET_FOR_MINGW" \
 --prefix="$PREFIX/$TARGET"

make install
cd ../..

# gcc stage one

mkdir build-gcc
cd build-gcc

../gcc-*/configure \
 --target="$TARGET" \
 --prefix="$PREFIX" \
 --disable-multilib \
 --enable-languages=c,c++ \
 --enable-threads=win32

make all-gcc -j$(nproc)
make install-gcc
cd ..

# mingw-w64-crt

cd mingw-w64/mingw-w64-crt

./configure \
 --host="$TARGET_FOR_MINGW" \
 --prefix="$PREFIX/$TARGET" \
 --with-default-msvcrt=msvcrt \
 STRIP="$PREFIX/bin/$TARGET-strip" \
 CC="$PREFIX/bin/$TARGET-gcc" \
 CXX="$PREFIX/bin/$TARGET-g++" \
 RANLIB="$PREFIX/bin/$TARGET-ranlib" \
 DLLTOOL="$PREFIX/bin/$TARGET-dlltool" \
 AR="$PREFIX/bin/$TARGET-ar" \
 AS="$PREFIX/bin/$TARGET-as" # this hell is caused by triplet mismatch

make -j$(nproc)
make install
cd ../..

# gcc stage two

cd build-gcc
make -j$(nproc)
make install
cd ..

# install libunicows

cp libunicows-*/libunicows.a "$PREFIX/$TARGET/lib"

# we're done

echo Ready. The toolchain is at $PREFIX.

# package

echo Compressing...
set +e
strip "$PREFIX/bin/"*
strip "$PREFIX/$TARGET/bin/"*
strip "$PREFIX/libexec/gcc/"*/*/lto*
strip "$PREFIX/libexec/gcc/"*/*/cc1*
ln -s build mingw-95
rm mingw-95.tar.xz
tar -c mingw-95 -f mingw-95.tar.xz -h -a
