<CsoundSyntheizer>
<CsLicense>

clang_hello.csd - this file tests the new Clang JIT compiler opcodes for 
Csound. It does nothing except prove the basics work.

Diagnostics starting with "*******" are from native Csound orchestra code.
Diagnostics starting with "#######" are from the Clang opcode internals.
Diagnostics starting with ">>>>>>>" are from C++ code.

</CsLicense>
<CsOptions>
-m0 --opcode-lib="./clang_opcodes.so" -otest.wav
</CsOptions>
<CsInstruments>

prints "******* I'm about to try compiling a simple test C++ module....\n"

gS_source_code = {{

#include "clang_invokable.hpp"
#include <csound/csdl.h>
#include <cstdio>
#include <iostream>
#include <string>
#include <vector>

// defined in this module to work around `__dso_handle` not being 
// defined in the C++ startup code.

void* __dso_handle = (void *)&__dso_handle;

extern "C" int csound_main(CSOUND *csound) {
    csound->Message(csound, ">>>>>>> Hello, world! This proves csound_main has been called with csound: %p.\\n", csound);
    std::vector<std::string> strings;
    strings.push_back("A test string...");
    csound->Message(csound, ">>>>>>> This proves a lot of libstdc++ stuff works: strings.size(): %ld strings[0]: %s\\n", strings.size(), strings[0].c_str());
    std::cerr << ">>>>>>> Now that we have manually defined our own __dso_handle, this proves std::cerr works as well!" << std::endl;
    return 0;
};

struct Hello : public ClangInvokableBase {
    int init(CSOUND *csound, OPDS *opds, MYFLT **outputs, MYFLT **inputs) override {
        csound->Message(csound, ">>>>>>> This proves clang_invoke has called into this module.\\n");
        const char *result = ">>>>>>> This proves clang_invoke can be used as an opcode that returns a string and multiplies a number by 2.";
        STRINGDAT *message = (STRINGDAT *)outputs[0];
        message->data = csound->Strdup(csound, (char *)result);
        message->size = std::strlen(result);
        MYFLT number = *inputs[0];
        MYFLT multiplied = number * 2.;
        *outputs[1] = multiplied;
        return OK;
    }
};

extern "C" {
    ClangInvokable *hello_factory() {
        auto instance = new Hello();
        std::fprintf(stderr, ">>>>>>> hello_factory created: %p\\n", instance);
        return instance;
    }
};

}}

gi_result clang_compile "csound_main", gS_source_code, "-v -std=c++14 -I/usr/local/include/csound -I.", "/usr/lib/gcc/x86_64-linux-gnu/9/libstdc++.so /usr/lib/gcc/x86_64-linux-gnu/9/libgcc_s.so /usr/lib/x86_64-linux-gnu/libm.so /usr/lib/x86_64-linux-gnu/libpthread.so"

instr 1
prints "******* Trying to invoke Hello...\n"
S_message, i_number clang_invoke "hello_factory", 1, 2
prints "******* clang_invoke returned: \"%s\" and %d\n", S_message, i_number
endin

</CsInstruments>
<CsScore>
f 0 30
i 1 5 5
</CsScore>
</CsoundSynthesizer>
