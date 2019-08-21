#!/bin/bash

set -e

autoreconf --install
chmod +x configure
which make
make --version

case `uname` in
    Darwin|Linux)
        export CFLAGS="-O3 -g -fPIC $CFLAGS"
        ./configure --prefix=$PREFIX --with-e-antic=$PREFIX --with-nauty=$PREFIX --with-flint=$PREFIX --with-gmp=$PREFIX
        ;;
    MINGW*)
        export PATH="$PREFIX/Library/bin:$BUILD_PREFIX/Library/bin:$RECIPE_DIR:$PATH"
        export CC=cl_wrapper.sh
        export CXX=cl_wrapper.sh
        export RANLIB=llvm-ranlib
        export AS=llvm-as
        export AR=llvm-ar
        export LD=lld-link
        export CCCL=clang-cl
        export CFLAGS="-MD -I$PREFIX/Library/include -O2 -D_CRT_SECURE_NO_WARNINGS"
        export CXXFLAGS="-MD -I$PREFIX/Library/include -O2 -EHs -D_CRT_SECURE_NO_WARNINGS"
        export LDFLAGS="$LDFLAGS -L$PREFIX/Library/lib"
        export lt_cv_deplibs_check_method=pass_all
        export LIBS="-llibomp"
        cp $PREFIX/Library/lib/gmp.lib $PREFIX/Library/lib/gmpxx.lib
        ./configure --prefix="$PREFIX/Library" --with-nauty=$PREFIX -with-gmp="$PREFIX/Library" || (cat config.log; false)
        # libtool has support for using either nm or dumpbin, but neither works correctly with C++ mangling schemes
        # cmake's dll creation tool works, but need to hack libtool to get it working
        sed -i.bak "s/export_symbols_cmds=/export_symbols_cmds2=/g" libtool
        sed "s/archive_expsym_cmds=/archive_expsym_cmds2=/g" libtool > libtool2
        cp $RECIPE_DIR/libtool_patch.sh libtool
        cat libtool2 >> libtool
        ;;
esac

make -j${CPU_COUNT}
make check -k || (ls -alR test/run_tests && exit 1)
make install

if [[ `uname` == MINGW* ]]; then
    PROJECT=normaliz
    LIBRARY_LIB=$PREFIX/Library/lib
    mv "${LIBRARY_LIB}/${PROJECT}.lib" "${LIBRARY_LIB}/${PROJECT}_static.lib"
    mv "${LIBRARY_LIB}/${PROJECT}.dll.lib" "${LIBRARY_LIB}/${PROJECT}.lib"
    rm $PREFIX/Library/lib/gmpxx.lib
fi
