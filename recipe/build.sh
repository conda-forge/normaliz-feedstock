#!/bin/bash

set -e
set -x

autoreconf -vfi
chmod +x configure

case "$target_platform" in
    linux*|osx*)
        # Get an updated config.sub and config.guess
        cp $BUILD_PREFIX/share/gnuconfig/config.* ./cnf
        export CFLAGS="-O3 -g -fPIC $CFLAGS"
        ./configure --prefix=$PREFIX --with-e-antic=$PREFIX --with-nauty=$PREFIX --with-flint=$PREFIX --with-gmp=$PREFIX || (cat config.log; false)
        ;;
    win*)
        cp $PREFIX/lib/gmp.lib $PREFIX/lib/gmpxx.lib
        sed -i.bak "s/-Wl,-rpath,/-L/g" configure
        sed -i.bak "s@#include <sys/time.h>@@g" \
	    source/libnormaliz/full_cone.h \
	    source/libnormaliz/general.cpp
        sed -i.bak "s@ssize_t@long long@g" \
            source/libnormaliz/matrix.cpp \
            source/libnormaliz/simplex.cpp \
            source/libnormaliz/face_lattice.cpp \
            source/libnormaliz/full_cone.cpp
        unset INCLUDE
        ./configure --prefix="$PREFIX" --with-nauty=$PREFIX --with-gmp="$PREFIX" || (cat config.log; false)
        patch_libtool
        echo $?
        ;;
esac

make -j${CPU_COUNT} V=1 -k
echo $?
if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
  if [[ "$target_platform" = linux-* ]]; then
    make check -j${CPU_COUNT} -k
  else
    make check -j${CPU_COUNT} -k || true;
  fi
fi
make install
echo $?

if [[ "$target_platform" == win* ]]; then
    rm $PREFIX/lib/gmpxx.lib
fi
echo $?
