<CsoundSyntheizer>
<CsLicense>

clang_hello.csd - this file tests the new Clang JIT compiler opcodes for 
Csound. This does nothing beside prove the basics work.

Author: Michael Gogins

Diagnostics starting with "*******" are from native Csound orchestra code.
Diagnostics starting with "#######" are from the Clang opcodes.
Diagnostics starting with ">>>>>>>" are from C++ code in the Csound orchestra.

</CsLicense>
<CsOptions>z
-m195 -otest.wav
</CsOptions>
<CsInstruments>

prints "******* I'm about to try compiling a simple test C++ module....\n"

gS_source_code = {{

#include <csound/csdl.h>
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include "clang_invokable.hpp"


/**
 * Must be defined in this module to work around `__dso_handle` not being 
 * defined in the C++ startup code.
 */

void* __dso_handle = (void *)&__dso_handle;

extern "C" int csound_main(CSOUND *csound) {
    csound->Message(csound, "\\n>>>>>>> Hello, world! This proves csound_main has been called with csound: %p.\\n", csound);
    std::vector<std::string> strings;
    strings.push_back("A test string...");
    csound->Message(csound, "\\n>>>>>>> This proves that a lot of libstdc++ stuff works: strings.size(): %ld strings[0]: %s\\n", strings.size(), strings[0].c_str());
    std::cerr << "Now that we have manually defined our own __dso_handle, this proves std::cerr works as well!\\n" << std::endl;
    return 0;
};

class Hello : public ClangInvokableBase {
    public:
    int init(CSOUND *csound, OPDS *opds, MYFLT **outputs, MYFLT **inputs) override {
	    csound->Message(csound, ">>>>>>> Hello, world! This proves that `clang_invoke` has called into this module.\\n");
	    const char *result = ">>>>>>> This proves that `clang_invoke` can be used as an opcode that returns a string and multiplies a number by 2.";
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
	    std::fprintf(stderr, ">>>>>>> hello_factory newed: %p\\n", instance);
	    return instance;
	}
};

}}

gi_result clang_compile "csound_main", gS_source_code, "-v -std=c++14 -I/usr/local/include/csound -I. -stdlib=libstdc++", "/usr/lib/gcc/x86_64-linux-gnu/9/libstdc++.so /usr/lib/gcc/x86_64-linux-gnu/9/libgcc_s.so /usr/lib/x86_64-linux-gnu/libm.so /usr/lib/x86_64-linux-gnu/libpthread.so"

instr 1
prints "******* Trying to invoke Hello...\n"
S_message, i_number clang_invoke "hello_factory", 1, 2
prints "******* Hello, world! `clang_invoke` returned: \"%s\" and %d\n", S_message, i_number
endin

</CsInstruments>
<CsScore>
f 0 30
i 1 5 5
</CsScore>
</CsoundSynthesizer>
