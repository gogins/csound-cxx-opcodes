<CsoundSyntheizer>
<CsOptions>
-m0 --opcode-lib="./clang_opcodes.so"
</CsOptions>
<CsInstruments>

gS_source_code = {{

    #include <csound/csdl.h>

    extern "C" void entry_point(CSOUND *csound) {
        csound->Message(csound, "Hello, World!\\n");
    };

}}

gi_result clang_compile "entry_point", gS_source_code, "-I/usr/local/include/csound", "/usr/lib/gcc/x86_64-linux-gnu/9/libstdc++.so"

</CsInstruments>
<CsScore>
f 0 1
</CsScore>
</CsoundSynthesizer>
