#!/bin/bash
export_symbols_cmds="echo \$libobjs | \$SED 's/ /\n/g'  > \$export_symbols.tmp && cmake -E __create_def \$export_symbols \$export_symbols.tmp"
archive_expsym_cmds="\$CC -o \$tool_output_objdir\$soname \$libobjs \$compiler_flags \$deplibs -Wl,-DEF:\\\"\$export_symbols\\\" -Wl,-DLL,-IMPLIB:\\\"\$tool_output_objdir\$libname.dll.lib\\\"; echo "
