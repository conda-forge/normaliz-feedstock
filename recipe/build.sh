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
        export PATH="$PREFIX/Library/bin:$BUILD_PREFIX/Library/bin:$RECIPE_DIR:$PATH"
        export CC=clang.exe
        export CXX=clang++.exe
        export RANLIB=llvm-ranlib
        export AS=llvm-as
        export AR=llvm-ar
        export LD=lld-link
        export CCCL=clang-cl
        export CFLAGS="-I$PREFIX/Library/include -O2 -D_CRT_SECURE_NO_WARNINGS"
        export CXXFLAGS="-I$PREFIX/Library/include -O2 -D_CRT_SECURE_NO_WARNINGS"
        export LDFLAGS="$LDFLAGS -L$PREFIX/Library/lib -fuse-ld=lld"
        export lt_cv_deplibs_check_method=pass_all
        cp $PREFIX/Library/lib/gmp.lib $PREFIX/Library/lib/gmpxx.lib
        ./configure --prefix="$PREFIX/Library" --with-nauty=$PREFIX -with-gmp="$PREFIX/Library" || (cat config.log; false)

        # libtool has support for using either nm or dumpbin, but neither works correctly with C++ mangling schemes.
        # libtool also uses /EXPORT directives which only clang-cl understands.
        # cmake's dll creation tool works, but need to hack libtool to get it working
        sed -i.bak 's/export_symbols_cmds=/export_symbols_cmds2=/g' libtool
        sed -i.bak 's/|-fuse-linker-plugin|/|-fuse-linker-plugin|-fuse-ld=*|/g' libtool
        sed 's/archive_expsym_cmds=/archive_expsym_cmds2=/g' libtool > libtool2
        echo "#!/bin/bash" > libtool
        echo "export_symbols_cmds=\"echo \\\$libobjs | \\\$SED 's/ /\n/g'  > \\\$export_symbols.tmp && cmake -E __create_def \\\$export_symbols \\\$export_symbols.tmp\"" >> libtool
        echo "archive_expsym_cmds=\"\\\$CC -o \\\$tool_output_objdir\\\$soname \\\$libobjs \\\$compiler_flags \\\$deplibs -Wl,-DEF:\\\\\\\"\\\$export_symbols\\\\\\\" -Wl,-DLL,-IMPLIB:\\\\\\\"\\\$tool_output_objdir\\\$libname.dll.lib\\\\\\\"; echo \"" >> libtool
        cat libtool2 >> libtool
        ;;
esac

make -j${CPU_COUNT}
make check -j${CPU_COUNT}
make install

if [[ "$target_platform" == win* ]]; then
    PROJECT=normaliz
    LIBRARY_LIB=$PREFIX/Library/lib
    mv "${LIBRARY_LIB}/${PROJECT}.lib" "${LIBRARY_LIB}/${PROJECT}_static.lib"
    mv "${LIBRARY_LIB}/${PROJECT}.dll.lib" "${LIBRARY_LIB}/${PROJECT}.lib"
    rm $PREFIX/Library/lib/gmpxx.lib
fi
