#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* ./cnf

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
        sed -i.bak "s/-Wl,-rpath,/-L/g" configure
        # https://github.com/Normaliz/Normaliz/pull/353/files
        echo -e "#include <ctime>\n$(cat source/maxsimplex/maxsimplex.cpp)" > source/maxsimplex/maxsimplex.cpp
        ./configure --prefix="$PREFIX" --with-nauty=$PREFIX --with-gmp="$PREFIX" || (cat config.log; false)
        patch_libtool
        echo $?
        ;;
esac

make -j${CPU_COUNT}
echo $?
if [[ "$PKG_VERSION" == "3.8.5" ]]; then
if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
  make check -j${CPU_COUNT} || true;
fi
else
  make check -j${CPU_COUNT}
fi
make install
echo $?

if [[ "$target_platform" == win* ]]; then
    rm $PREFIX/lib/gmpxx.lib
fi
echo $?
