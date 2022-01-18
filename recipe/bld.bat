set "REMOVE_LIB_PREFIX=no"
del "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Tools\MSVC\14.16.27023\include\omp.h"
call %BUILD_PREFIX%\Library\bin\run_autotools_clang_conda_build.bat
if errorlevel 1 exit 1
