<CsoundSyntheizer>
<CsLicense>

clang_hello.csd - this file tests the new Clang JIT compiler opcodes for 
Csound. It does nothing except prove the basics work.

Diagnostics starting with "*******" are from native Csound orchestra code.
Diagnostics starting with "#######" are from the Clang opcode internals.
Diagnostics starting with ">>>>>>>" are from C++ code.

Copyright (C) 2021 by Michael Gogins

This file is part of clang-opcodes.

clang-opcodes is free software; you can redistribute it
and/or modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

clang-opcodes is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with clang-opcodes; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
02110-1301 USA

</CsLicense>
<CsOptions>
-m0 --opcode-lib="./clang_opcodes.so" -otest.wav
</CsOptions>
<CsInstruments>

prints "******* I'm about to try compiling a simple test C++ module....\n"

gS_source_code = {{

#include <csdl.h>
#include <clang_invokable.hpp>
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

// For Darwin:
// gi_result clang_compile "csound_main", gS_source_code, "-v -resource-dir -I/Users/michaelgogins/clang-opcodes -I/opt/homebrew/Cellar/llvm/13.0.0_2 -I/Library/Frameworks/CsoundLib64.framework/Headers -I/opt/homebrew/cellar/llvm/13.0.0_2/include/c++/v1 -I/Library/Developer/CommandLineTools/SDKs/MacOSX12.sdk/usr/include -F/Library/Developer/CommandLineTools/SDKs/MacOSX12.sdk/System/Library/Frameworks -I/Users/michaelgogins/clang-opcodes -std=c++17", "-lstdc++ -m"

//gi_result clang_compile "csound_main", gS_source_code, "-v -std=c++17 -I/opt/homebrew/Cellar/csound/6.16.2_2/include/csound -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -I/Users/michaelgogins/clang-opcodes", "-lstdc++ -m"

//gi_result clang_compile "csound_main", gS_source_code, "-v -std=c++17 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -I/Users/michaelgogins/clang-opcodes -I/opt/homebrew/Cellar/csound/6.16.2_2/Frameworks/CsoundLib64.framework/Versions/6.0/Headers", "-lstdc++ -m"

// Getting the JIT compiler options correct is tricky. Symlinks are not 
// followed, so complete paths must be used. The -resource-dir flag must have 
// same value as for standalone, homebrew-installed clang-13; look at the 
// opcode build diagnostics to find that path.

//gi_result clang_compile "csound_main", gS_source_code, "-v -d -resource-dir /opt/homebrew/Cellar/llvm/13.0.0_2/lib/clang/13.0.0 -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX12.sdk -I/opt/homebrew/Cellar/llvm/13.0.0_2/include -std=c++14 -stdlib=libc++ -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -I/Library/Frameworks/CsoundLib64.framework/Versions/6.0/Headers -I/opt/homebrew/cellar/llvm/13.0.0_2/include/c++/v1 -I/opt/homebrew/Cellar/llvm/13.0.0_2/lib/clang/13.0.0/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include -F/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks", "-lstdc++ -m"

gi_result clang_compile "csound_main", gS_source_code, "-v -d -resource-dir /opt/homebrew/Cellar/llvm/13.0.0_2/lib/clang/13.0.0 -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX12.sdk -std=c++14 -stdlib=libc++ -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -I/Library/Frameworks/CsoundLib64.framework/Versions/6.0/Headers -I/opt/homebrew/cellar/llvm/13.0.0_2/include/c++/v1 -I/opt/homebrew/Cellar/llvm/13.0.0_2/lib/clang/13.0.0/include -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include -F/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks", "-lstdc++ -m"

// For Linux:
// gi_result clang_compile "csound_main", gS_source_code, "-v -std=c++17 -isysroot / -I/Users/michaelgogins/clang-opcodes -I/usr/local/include/csound -I.", "/usr/lib/gcc/x86_64-linux-gnu/9/libstdc++.so /usr/lib/gcc/x86_64-linux-gnu/9/libgcc_s.so /usr/lib/x86_64-linux-gnu/libm.so /usr/lib/x86_64-linux-gnu/libpthread.so"

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
