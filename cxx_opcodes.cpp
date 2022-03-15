/**
 * cxx_opcodes.cpp - this file is part of cxx-opcodes.
 *
 * Copyright (C) 2021 by Michael Gogins
 * 
 * cxx-opcodes is free software; you can redistribute it
 * and/or modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * cxxopcodes is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with cxx-opcodes; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
 * Michael Gogins<br>
 * https://github.com/gogins<br>
 * http://michaelgogins.tumblr.com
 *
 * This file implements Csound opcodes that compile C or C++ source code,
 * embedded in tne Csound orchestra, for any purpose, and invoke the compiled 
 * code. The gcc toolchain (or a compatible toolchain) must be installed on 
 * the system and will be invoked to compile, link, load, and call into the 
 * compiled code. The toolchain must therefore be in Csound's executable path.
 *
 * ## Syntax
 *```
 * i_result cxx S_unique_entry_point, S_source_code, S_compiler_options
 *
 * The compiler options must be given in the same form as would be used to 
 * compile and link a single C++ file to a Csound plugin opcode.
 * ```
 */

#if defined(__APPLE__)
#include <csdl.h>
#include <csound.h>
#include <OpcodeBase.hpp>
#include <unistd.h>
#else
#include <csdl.h>
#include <csound.h>
#include <OpcodeBase.hpp>
#endif
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <mutex>
#include <stdlib.h>
#include <string>
#include <vector>


/**
 * Diagnostics are global for all these opcodes, and also for 
 * all modules compiled by these opcodes.
 */
PUBLIC bool &cxx_diagnostics_enabled() {
    static bool enabled = false;
    return enabled;
}

static void tokenize(std::string const &string_, const char delimiter, std::vector<std::string> &tokens) {
    size_t start;
    size_t end = 0;
    while ((start = string_.find_first_not_of(delimiter, end)) != std::string::npos)
    {
        end = string_.find(delimiter, start);
        tokens.push_back(string_.substr(start, end - start));
    }
}

/**
 * This contains handles to all dynamic link libraries compiled and loaded by 
 * these opcodes in this Csound process.
 */
static std::vector<void *> &loaded_modules() {
    static std::vector<void *> loaded_modules_;
    return loaded_modules_;
}

/**
 * The `cxx_compile` opcode will call a uniquely named function that must be 
 * defined in the module. The type of this function must be
 * `extern "C" int (*)(CSOUND *csound)`. This function serves as the entry 
 * point to the module, similar to 'main' in a C or C++ program.
 *
 * When the entry point is called, `csoundStart` has _already_ been called,
 * and Csound is performing an init pass, which for `cxx_compile` used in the
 * orchestra header will be the first init pass in the orchestra header
 * (that is, "instr 0").
 */
extern "C" {
    typedef int (*csound_main_t)(CSOUND *csound);
};

class CxxCompile : public csound::OpcodeBase<CxxCompile>
{
public:
    // OUTPUTS
    MYFLT *i_result;
    // INPUTS
    STRINGDAT *S_entry_point;
    STRINGDAT *S_source_code;
    STRINGDAT *S_compiler_options;
    // STATE
    /**
     * This is an i-time only opcode. Everything happens in init.
     */
    int init(CSOUND *csound)
    {
    	cxx_diagnostics_enabled() = false;
        // Parse the compiler options.
        auto compiler_options = csound->strarg2name(csound, (char *)0, S_compiler_options->data, (char *)"", 1);
        std::vector<const char*> args;
        std::vector<std::string> tokens;
        tokenize(compiler_options, ' ', tokens);
        for (int i = 0; i < tokens.size(); ++i) {
            if (tokens[i] == "-v") {
                cxx_diagnostics_enabled() = true;
            }
            args.push_back(tokens[i].c_str());
        }
        //std::fprintf(stderr, "CxxCompile::init: line %d\n", __LINE__);
        auto entry_point = csound->strarg2name(csound, (char *)0, S_entry_point->data, (char *)"", 1);
        if (cxx_diagnostics_enabled()) csound->Message(csound, "####### cxx_compile: entry_point: %s\n", entry_point);
        // Create a temporary file containing the source code.
        auto source_code = csound->strarg2name(csound, (char *)0, S_source_code->data, (char *)"", 1);
        const char *temp_directory = std::getenv("TMPDIR");
        if (temp_directory == nullptr) {
            temp_directory = "/tmp";
        }
        char filepath[0x500];
        std::snprintf(filepath, 0x500, "%s/cxx_opcode_XXXXXX.cpp", temp_directory);
        auto file_descriptor = mkstemps(filepath, 4);
        auto file_ = fdopen(file_descriptor, "w");
        std::fwrite(source_code, strlen(source_code), sizeof(source_code[0]), file_);
        std::fclose(file_);
        args.push_back("cxx_opcode");
        args.push_back(filepath);
        char module_filepath[0x600];
        std::snprintf(module_filepath, 0x600, "%s.so", filepath);
        char command_buffer[0x2000];
        std::snprintf(command_buffer, 0x2000, "g++ %s %s -o%s\n", filepath, S_compiler_options->data, module_filepath);
        auto result = std::system(command_buffer);
	    // Compile the source code to a module, and call its
        // csound_main entry point.
        if (result == 0) {
            void *module_handle = nullptr;
            result = csound->OpenLibrary(&module_handle, module_filepath);
            loaded_modules().push_back(module_handle);
            csound_main_t entry_point_symbol = (csound_main_t) csound->GetLibrarySymbol(module_handle, entry_point);
            if (cxx_diagnostics_enabled()) {
                csound->Message(csound, "####### cxx_compile: loading:      %s\n", module_filepath);
                csound->Message(csound, "####### cxx_compile: handle:       %p\n", module_handle);
                csound->Message(csound, "####### cxx_compile: entry point:  %s\n", entry_point);
                csound->Message(csound, "####### cxx_compile: symbol:       %p\n", entry_point_symbol);
            }
            result = entry_point_symbol(csound);
        }
        return result;
    };
};

#include "cxx_invokable.hpp"

static std::mutex invokable_mutex;

/**
 * Assuming that `cxx_compile` has already compiled a module that
 * implements a `CxxInvokable`, creates an instance of that
 * `CxxInvokable` and invokes it.
 */
class CxxInvoke : public csound::OpcodeNoteoffBase<CxxInvoke>
{
public:
    // OUTPUTS
    MYFLT *outputs[40];
    // INPUTS
    STRINGDAT *S_invokable_factory;
/* thread vals, where isub=1, ksub=2:
   0 =     1  OR   2  (B out only)
   1 =     1
   2 =             2
   3 =     1  AND  2
 */

    MYFLT *i_thread;
    MYFLT *inputs[VARGMAX];
    // STATE
    int thread;
    std::shared_ptr<CxxInvokable> cxx_invokable;
    int init(CSOUND *csound)
    {
        std::lock_guard<std::mutex> lock(invokable_mutex);
        int result = OK;
        thread = (int) *i_thread;
        // Look up factory.
        auto invokable_factory_name = S_invokable_factory->data;
        if (cxx_diagnostics_enabled()) csound->Message(csound,     "####### cxx_invoke::init: invokable_factory_name:  \"%s\"\n", invokable_factory_name);
        // Create instance. We simply search through all the dynamic link 
        // libraries compiled and loaded by this Csound process. TODO: If it 
        // turns out that there are hundreds of these, make this more 
        // efficient.
        for (auto module_handle : loaded_modules()) {
            if (cxx_diagnostics_enabled()) csound->Message(csound, "####### cxx_invoke::init: library handle:          %p\n", module_handle);
	        auto invokable_factory = (CxxInvokable *(*)()) csound->GetLibrarySymbol(module_handle, invokable_factory_name);
	        if (invokable_factory != nullptr) {
                if (cxx_diagnostics_enabled()) csound->Message(csound, "####### cxx_invoke::init: found invokable factory: %p\n", invokable_factory);
                auto instance = invokable_factory();
              	if (cxx_diagnostics_enabled()) csound->Message(csound, "####### cxx_invoke::init: created new invokable:   %p for thread: %d\n", instance, thread);
	            cxx_invokable.reset(instance);
                if (thread == 2) {
                    return result;
                }
                // Invoke the instance.
                result = cxx_invokable->init(csound, &opds, outputs, inputs);
                if (cxx_diagnostics_enabled()) csound->Message(csound, "####### cxx_invoke::init: result of invokation:    %d\n", result);
                return result;
            }
        }
        return result;
    }
    int kontrol(CSOUND *csound)
    {
        int result = OK;
        if (thread == 1) {
            return result;
        }
        result = cxx_invokable->kontrol(csound, outputs, inputs);
        return result;

    }
    int noteoff(CSOUND *csound) {
        if (cxx_diagnostics_enabled()) csound->Message(csound, "####### cxx_invoke::noteoff\n");
        int result = OK;
        result = cxx_invokable->noteoff(csound);
        if (cxx_diagnostics_enabled()) csound->Message(csound, "####### cxx_invoke::noteoff: invokable::noteoff: result: %d\n", result);
        cxx_invokable.reset();
    	return result;
    }
};

extern "C" {

    PUBLIC int csoundModuleInit_cxx_opcodes(CSOUND *csound)
    {
        int status = csound->AppendOpcode(csound,
                                          (char *)"cxx_compile",
                                          sizeof(CxxCompile),
                                          0,
                                          1,
                                          (char *)"i",
                                          (char *)"SSW",
                                          (int (*)(CSOUND*,void*)) CxxCompile::init_,
                                          (int (*)(CSOUND*,void*)) 0,
                                          (int (*)(CSOUND*,void*)) 0);
        status += csound->AppendOpcode(csound,
                                          (char *)"cxx_invoke",
                                          sizeof(CxxInvoke),
                                          0,
                                          3,
                                          (char *)"****************************************",
                                          (char *)"SkN",
                                          (int (*)(CSOUND*,void*)) CxxInvoke::init_,
                                          (int (*)(CSOUND*,void*)) CxxInvoke::kontrol_,
                                          (int (*)(CSOUND*,void*)) 0);
        return status;
    }

    PUBLIC int csoundModuleDestroy_cxx_opcodes(CSOUND *csound)
    {
        loaded_modules().clear();
        return 0;
    }

#ifndef INIT_STATIC_MODULES
    PUBLIC int csoundModuleCreate(CSOUND *csound)
    {
        return 0;
    }

    PUBLIC int csoundModuleInit(CSOUND *csound)
    {
        return csoundModuleInit_cxx_opcodes(csound);
    }

    PUBLIC int csoundModuleDestroy(CSOUND *csound)
    {
        return csoundModuleDestroy_cxx_opcodes(csound);
    }
#endif
}
