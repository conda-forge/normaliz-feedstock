#!/bin/bash

set -e

autoreconf --install
chmod +x configure

case "$target_platform" in
    linux*|osx*)
        export CFLAGS="-O3 -g -fPIC $CFLAGS"
        ./configure --prefix=$PREFIX --with-e-antic=$PREFIX --with-nauty=$PREFIX --with-flint=$PREFIX --with-gmp=$PREFIX
        ;;
    win*)
        cp $PREFIX/Library/lib/gmp.lib $PREFIX/Library/lib/gmpxx.lib
        ./configure --prefix="$PREFIX/Library" --with-nauty=$PREFIX -with-gmp="$PREFIX/Library" || (cat config.log; false)
        ;;
esac

make -j${CPU_COUNT}
make check -j${CPU_COUNT}
make install

if [[ "$target_platform" == win* ]]; then
    rm $PREFIX/Library/lib/gmpxx.lib
fi
