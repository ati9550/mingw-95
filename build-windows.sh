#!/bin/bash
# build-windows.sh - script compiling the toolchain to run on Windows
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
	rm -rf mingw-w64
	rm -rf binutils-*
	rm -rf gmp-*
	rm -rf mpfr-*
	rm -rf mpc-*
	rm -rf gcc-*
	rm -rf libunicows-*

	set -e

	mkdir src
	cd src

	# wget https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz  # their ftp is
	# wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz           # not reliable
	# wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz
	# wget https://ftp.gnu.org/gnu/mpc/mpc-1.4.1.tar.xz
	# wget https://ftp.gnu.org/gnu/gcc/gcc-12.5.0/gcc-12.5.0.tar.xz

	wget https://mirror.truenetwork.ru/gnu/binutils/binutils-2.42.tar.xz
	wget https://mirror.truenetwork.ru/gnu/gmp/gmp-6.3.0.tar.xz
	wget https://mirror.truenetwork.ru/gnu/mpfr/mpfr-4.2.2.tar.xz
	wget https://mirror.truenetwork.ru/gnu/mpc/mpc-1.4.1.tar.xz
	wget https://mirror.truenetwork.ru/gnu/gcc/gcc-12.5.0/gcc-12.5.0.tar.xz
	wget https://prdownloads.sourceforge.net/libunicows/libunicows-1.1.1-mingw32.zip

	cd ..
	tar -xf src/binutils-*.tar.xz
	tar -xf src/gmp-*.tar.xz
	tar -xf src/mpfr-*.tar.xz
	tar -xf src/mpc-*.tar.xz
	tar -xf src/gcc-*.tar.xz
	unzip src/libunicows-*.zip

	git clone https://github.com/mingw-w64/mingw-w64.git
	cd mingw-w64
	git checkout v14.0.0
	cd ..

	cd binutils-*
	patch -p1 < ../fix-binutils-disable-wfopen.patch
	cd ..

	cd gcc-*
	patch -p1 < ../fix-gcc-win95-interlock-compare-exchange.patch
	patch -p1 < ../fix-gcc-disable-quick-exit.patch
	cd ..

	set +e
	touch download_success.log
fi

# target dir

if [ -z "$PREFIX" ]; then
	set +e
	rm -r build-windows

	set -e
	mkdir build-windows
	export PREFIX="$PWD/build-windows"
fi

set -e

export TARGET=i586-w64-mingw32
export TARGET_FOR_MINGW=i686-w64-mingw32 # it will not accept i586

# setting up cross compilation

if [ -z "$CROSS_COMPILE" ]; then
	export CROSS_COMPILE="$PWD/build/bin/$TARGET-" # using mingw-95 by default
fi

if [ ! -f "${CROSS_COMPILE}gcc" ]; then
	echo "Error: cross compilation compiler is not found at ${CROSS_COMPILE}gcc" >&2
	exit 1
fi

export CROSS_COMPILE_BIN="$(dirname "${CROSS_COMPILE}gcc")"

export STRIP="${CROSS_COMPILE}strip" \
 CC="${CROSS_COMPILE}gcc" \
 CXX="${CROSS_COMPILE}g++" \
 RANLIB="${CROSS_COMPILE}ranlib" \
 DLLTOOL="${CROSS_COMPILE}dlltool" \
 AR="${CROSS_COMPILE}ar" \
 AS="${CROSS_COMPILE}as" \
 OBJDUMP="${CROSS_COMPILE}objdump" \
 LDFLAGS="-Wl,-no-undefined" \
 CFLAGS="-D__MSVCRT_VERSION__=0x400 \
 -D_WIN32_WINNT=0x0400 -DWINVER=0x0400" \
 CXXFLAGS="-D__MSVCRT_VERSION__=0x400 \
 -D_WIN32_WINNT=0x0400 -DWINVER=0x0400" # TODO: make those flags the default

# clean

set +e

rm -rf build-windows-binutils
rm -rf build-windows-gmp
rm -rf build-windows-mpfr
rm -rf build-windows-mpc
rm -rf build-windows-gcc
export OLDPWD="$PWD"

cd mingw-w64/mingw-w64-headers &&
make clean
cd "$OLDPWD"

cd mingw-w64/mingw-w64-crt &&
make clean
cd "$OLDPWD"

set -e

# binutils

mkdir build-windows-binutils
cd build-windows-binutils

../binutils-*/configure \
 --target="$TARGET" \
 --prefix="$PREFIX" \
 --disable-multilib \
 --host="$TARGET"

make -j$(nproc)
make install
cd ..

# gmp

mkdir build-windows-gmp
cd build-windows-gmp

../gmp-*/configure \
 --target="$TARGET" \
 --prefix="$PREFIX" \
 --disable-static \
 --enable-shared \
 --host="$TARGET"

make -j$(nproc)
make install
cd ..

# mpfr

mkdir build-windows-mpfr
cd build-windows-mpfr

../mpfr-*/configure \
 --target="$TARGET" \
 --prefix="$PREFIX" \
 --disable-static \
 --enable-shared \
 --with-gmp-include="$PREFIX/include" \
 --with-gmp-lib="$PREFIX/lib" \
 --host="$TARGET"

make -j$(nproc)
make install
cd ..

# mpc

mkdir build-windows-mpc
cd build-windows-mpc

../mpc-*/configure \
 --target="$TARGET" \
 --prefix="$PREFIX" \
 --disable-static \
 --enable-shared \
 --with-gmp-include="$PREFIX/include" \
 --with-gmp-lib="$PREFIX/lib" \
 --with-mpfr-include="$PREFIX/include" \
 --with-mpfr-lib="$PREFIX/lib" \
 --host="$TARGET"

make -j$(nproc)
make install
cd ..

# mingw-w64-headers

cd mingw-w64/mingw-w64-headers

./configure \
 --host="$TARGET_FOR_MINGW" \
 --prefix="$PREFIX/$TARGET" \
 --with-default-msvcrt=msvcrt40 \
 --with-default-win32-winnt=0x0400 \
 CFLAGS="" \
 CXXFLAGS=""

make install
cd ../..

# gcc stage one

mkdir build-windows-gcc
cd build-windows-gcc

../gcc-*/configure \
 --target="$TARGET" \
 --prefix="$PREFIX" \
 --disable-multilib \
 --enable-languages=c,c++ \
 --enable-threads=win32 \
 --with-gmp-include="$PREFIX/include" \
 --with-gmp-lib="$PREFIX/lib" \
 --with-mpfr-include="$PREFIX/include" \
 --with-mpfr-lib="$PREFIX/lib" \
 --with-mpc-include="$PREFIX/include" \
 --with-mpc-lib="$PREFIX/lib" \
 --enable-shared \
 CFLAGS="$CFLAGS -DWIN32_LEAN_AND_MEAN" \
 CXXFLAGS="$CXXFLAGS -DWIN32_LEAN_AND_MEAN" \
 PATH="$CROSS_COMPILE_BIN:$PATH" \
 --host="$TARGET" # this flag prevents the use of Windows abort function

PATH="$CROSS_COMPILE_BIN:$PATH" make all-gcc -j$(nproc)
PATH="$CROSS_COMPILE_BIN:$PATH" make install-gcc
cd ..

# mingw-w64-crt

cd mingw-w64/mingw-w64-crt

./configure \
 --host="$TARGET_FOR_MINGW" \
 --prefix="$PREFIX/$TARGET" \
 --with-default-msvcrt=msvcrt40 \
 --with-default-win32-winnt=0x0400 \
 CFLAGS="" \
 CXXFLAGS=""

make -j$(nproc)
make install
cd ../..

# gcc stage two

cd build-windows-gcc
PATH="$CROSS_COMPILE_BIN:$PATH" make -j$(nproc)
PATH="$CROSS_COMPILE_BIN:$PATH" make install
cd ..

# gcc fix missing DLLs

cp build-windows-gcc/i586-w64-mingw32/libgcc/shlib/libgcc_s_sjlj-1.dll \
 "$PREFIX/libexec/gcc/"*/* # is not installed at all for some reason

cd "$PREFIX"
cp lib/libgmp-*.dll bin # for gcc
cp lib/libgmp-*.dll libexec/gcc/*/* # for cc1
cp bin/libmpfr-*.dll libexec/gcc/*/* # for cc1
cp bin/libmpc-*.dll libexec/gcc/*/* # for cc1
cd "$OLDPWD"

# install libunicows

cp libunicows-*/libunicows.a "$PREFIX/$TARGET/lib"

# copy licenses

mkdir -p "$PREFIX/licenses/binutils"
cp binutils-*/COPYING* "$PREFIX/licenses/binutils"
mkdir -p "$PREFIX/licenses/gmp"
cp gmp-*/COPYING* "$PREFIX/licenses/gmp"
mkdir -p "$PREFIX/licenses/mpfr"
cp mpfr-*/COPYING* "$PREFIX/licenses/mpfr"
mkdir -p "$PREFIX/licenses/mpc"
cp mpc-*/COPYING* "$PREFIX/licenses/mpc"
mkdir -p "$PREFIX/licenses/gcc"
cp gcc-*/COPYING* "$PREFIX/licenses/gcc"
mkdir -p "$PREFIX/licenses/mingw-w64"
cp mingw-w64/COPYING mingw-w64/COPYING*/COPYING* \
 mingw-w64/DISCLAIMER* "$PREFIX/licenses/mingw-w64"
cp mingw-w64/mingw-w64-headers/ddk/readme.txt \
 "$PREFIX/licenses/mingw-w64/ddk-readme.txt"
mkdir -p "$PREFIX/licenses/libunicows"
cp libunicows-*/license.txt "$PREFIX/licenses/libunicows"

# we're done

echo Ready. The toolchain is at $PREFIX.

# package

echo Compressing...
set +e
strip "$PREFIX/bin/"*
strip "$PREFIX/$TARGET/bin/"*
strip "$PREFIX/libexec/gcc/"*/*/lto*
strip "$PREFIX/libexec/gcc/"*/*/cc1*
rm mingw-95-windows
ln -s build-windows mingw-95-windows
rm mingw-95-windows.zip                  # zip is less efficient, but on Windows
zip -r mingw-95-windows mingw-95-windows # you don't want to deal with tar
