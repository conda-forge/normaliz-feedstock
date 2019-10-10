#!/bin/bash

set -e
set -x

autoreconf --install
chmod +x configure

case "$target_platform" in
    linux*|osx*)
        export CFLAGS="-O3 -g -fPIC $CFLAGS"
        ./configure --prefix=$PREFIX --with-e-antic=$PREFIX --with-nauty=$PREFIX --with-flint=$PREFIX --with-gmp=$PREFIX
        ;;
    win*)
        cp $PREFIX/lib/gmp.lib $PREFIX/lib/gmpxx.lib
        ./configure --prefix="$PREFIX" --with-nauty=$PREFIX --with-gmp="$PREFIX" || (cat config.log; false)
        patch_libtool
        echo $?
        ;;
esac

make -j${CPU_COUNT}
echo $?
make check -j${CPU_COUNT}
echo $?
make install
echo $?

if [[ "$target_platform" == win* ]]; then
    rm $PREFIX/lib/gmpxx.lib
fi
echo $?
