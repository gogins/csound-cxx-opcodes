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
 * i_result cxx S_unique_entry_point, S_source_code, S_compiler_command
 *
 * The compiler options must be given in the same form as would be used to 
 * compile and link a single C++ file to a Csound plugin opcode.
 * ```
 */

#if defined(__APPLE__)
#include <unistd.h>
#endif
#include <csdl.h>
#include <csignal>
#include <csound.h>
#include <OpcodeBase.hpp>
#include <cstdio>
#include <cstdlib>
#if (defined(__linux__) || defined(__unix__) || defined(_POSIX_VERSION))
#include <dlfcn.h>
#endif
#include <filesystem>
#include <memory>
#include <mutex>
#include <random>
#include <stdlib.h>
#include <string>
#include <vector>
#if defined(WIN32)
#include <windows.h>
#endif

/**
 * Diagnostics are global for all these opcodes, and also for 
 * all modules compiled by these opcodes.
 */
PUBLIC bool &cxx_diagnostics_enabled() {
    static bool enabled = false;
    return enabled;
}

/**
 * Cross-platform facility for loading shared libraries upon which embedded 
 * code will depend. Such dependencies must be pre-loaded in global scope.
 * This is needed because csoundOpenLibrary does NOT load in global scope.
 */
static void *cxx_load_library(const char *library_name) {
    void *library_handle = nullptr;
#if defined(WIN32)
    library_handle = (void*) LoadLibrary(library_name);
    return library_handle;
#endif
#if (defined(__APPLE__) || defined(__linux__) || defined(__unix__) || defined(_POSIX_VERSION))
    library_handle = dlopen(library_name, RTLD_NOW | RTLD_GLOBAL);
#endif
    std::fprintf(stderr, "####### cxx_load_library: library_name: %s library_handle: %p\n", library_name, library_handle);
    return library_handle;
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

static std::mutex &get_mutex() {
    static std::mutex mutex_;
    return mutex_;
}

class CxxCompile : public csound::OpcodeBase<CxxCompile>
{
public:
    // OUTPUTS
    MYFLT *i_result;
    // INPUTS
    STRINGDAT *S_entry_point;
    STRINGDAT *S_source_code;
    // Compiler name and all compiler options except for source code filename,
    // output name, and dynamic link libraries.
    STRINGDAT *S_compiler_command;
    // All dynamic link libraries required by the compiler command.
    STRINGDAT *S_dynamic_link_libraries;
    // STATE
    /**
     * This is an i-time only opcode. Everything happens in init.
     */
    int init(CSOUND *csound)
    {
        cxx_diagnostics_enabled() = false;
        // Parse the compiler options.
        auto cxx_command = csound->strarg2name(csound, (char *)0, S_compiler_command->data, (char *)"", 1);
        std::vector<const char*> args;
        std::vector<std::string> tokens;
        tokenize(cxx_command, ' ', tokens);
        for (int i = 0; i < tokens.size(); ++i) {
            if (tokens[i] == "-v") {
                cxx_diagnostics_enabled() = true;
            }
            args.push_back(tokens[i].c_str());
        }
        //std::fprintf(stderr, "CxxCompile::init: line %d\n", __LINE__);
        auto entry_point = csound->strarg2name(csound, (char *)0, S_entry_point->data, (char *)"", 1);
        // Create a temporary file containing the source code.
        auto source_code = csound->strarg2name(csound, (char *)0, S_source_code->data, (char *)"", 1);
        char filepath[0x500];
        {
            std::lock_guard lock(get_mutex());
            std::mt19937 mersenne_twister;
            unsigned int seed_ = std::time(nullptr);
            mersenne_twister.seed(seed_);
            std::snprintf(filepath, 0x500, "%s/cxx_opcode_%lx.cpp", std::filesystem::temp_directory_path().c_str(), mersenne_twister());
            auto file_ = fopen(filepath, "w+");
            std::fwrite(source_code, strlen(source_code), sizeof(source_code[0]), file_);
            std::fclose(file_);
        }
        args.push_back("cxx_opcode");
        args.push_back(filepath);
        char module_filepath[0x600];
        std::snprintf(module_filepath, 0x600, "%s.so", filepath);
        char compiler_command[0x2000];
        std::snprintf(compiler_command, 0x2000, "%s %s -o%s\n", S_compiler_command->data, filepath, module_filepath);
        if (cxx_diagnostics_enabled()) {    
            csound->Message(csound, "####### cxx_compile: command:            %s\n", compiler_command);
        }
        auto result = std::system(compiler_command);
        if (cxx_diagnostics_enabled()) {
            csound->Message(csound, "####### cxx_compile: result:             %d\n", result);
        }
        // Compile the source code to a module, and call its
        // csound_main entry point.
        if (result == 0) {
            // First, preload dynamic link libraries required by our compiled 
            // module.
            if (S_dynamic_link_libraries != nullptr) {
                std::vector<std::string> dynamic_link_library_names;
                auto dynamic_link_libraries = csound->strarg2name(csound, (char *)0, S_dynamic_link_libraries->data, (char *)"", 1);
                tokenize(dynamic_link_libraries, ' ', dynamic_link_library_names);
                for (const auto &dynamic_link_library_name : dynamic_link_library_names) {
                    void *module_handle = nullptr;
                    auto library_result = cxx_load_library(dynamic_link_library_name.c_str());
#if (defined(__linux__) || defined(__unix__) || defined(_POSIX_VERSION)) 
                    if (result != OK) {
                            auto error_message = dlerror();
                            csound->Message(csound, "Error: dlerror: \"%s\" when trying to load %s\n", error_message, dynamic_link_library_name.c_str());
                    }
#endif
                    if (cxx_diagnostics_enabled() && library_result != nullptr) {
                        csound->Message(csound, "####### cxx_compile: loaded dependency:  %s\n", dynamic_link_library_name.c_str());
                    }
                }
            }
            // Then, load our compiled module.
            void *module_handle = nullptr;
            ///result = csound->OpenLibrary(&module_handle, module_filepath);
            module_handle = cxx_load_library(module_filepath);
#if (defined(__linux__) || defined(__unix__) || defined(_POSIX_VERSION)) 
            ///if (result != OK) {
            if (module_handle == nullptr) {
                    auto error_message = dlerror();
                    csound->Message(csound, "Error: dlerror: %s\n", error_message);
            }
#endif
            loaded_modules().push_back(module_handle);
            csound_main_t entry_point_symbol = (csound_main_t) csound->GetLibrarySymbol(module_handle, entry_point);
            if (cxx_diagnostics_enabled()) {
                csound->Message(csound, "####### cxx_compile: module_filepath:    %s\n", module_filepath);
                csound->Message(csound, "####### cxx_compile: module_handle:      %p\n", module_handle);
                csound->Message(csound, "####### cxx_compile: entry_point:        %s\n", entry_point);
                csound->Message(csound, "####### cxx_compile: entry_point_symbol: %p\n", entry_point_symbol);
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
    CxxInvokable *cxx_invokable;
    int init(CSOUND *csound)
    {
        std::lock_guard<std::mutex> lock(invokable_mutex);
        int result = OK;
        thread = (int) *i_thread;
        // Look up factory.
        auto invokable_factory_name = S_invokable_factory->data;
        if (cxx_diagnostics_enabled()) csound->Message(csound,     "####### cxx_invoke::init: invokable_factory_name:  \"%s\" cxx_invokable: %p\n", invokable_factory_name, cxx_invokable);
        // Create instance. We simply search through all the dynamic link 
        // libraries compiled and loaded by this Csound process. TODO: If it 
        // turns out that there are hundreds of these, make this more 
        // efficient.
        for (auto module_handle : loaded_modules()) {
            if (cxx_diagnostics_enabled()) csound->Message(csound, "####### cxx_invoke::init: library handle:          %p\n", module_handle);
            auto invokable_factory = (CxxInvokable *(*)()) csound->GetLibrarySymbol(module_handle, invokable_factory_name);
            if (invokable_factory != nullptr) {
                if (cxx_diagnostics_enabled()) csound->Message(csound, "####### cxx_invoke::init: found invokable factory: %p\n", invokable_factory);
                cxx_invokable= invokable_factory();
                if (cxx_diagnostics_enabled()) csound->Message(csound, "####### cxx_invoke::init: created new invokable:   %p for thread: %d\n", cxx_invokable, thread);
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
        if (cxx_invokable != nullptr) {
            delete cxx_invokable;
            cxx_invokable = nullptr;
        }
        return result;
    }
};

std::vector<std::string> get_operating_system() {
    std::string operating_system = "Unidentified operating system.";
    std::string macros;
#ifdef _WIN32
    macros += "_WIN32 ";
    operating_system = "Windows";
#endif
#ifdef __DARWIN__
    macros += "__DARWIN__ ";
    operating_system = "macOS";
#endif
#ifdef __MACH__
    macros += "__MACH__ ";
    operating_system = "macOS";
#endif
#ifdef __APPLE__
    macros += "__APPLE__ ";
    operating_system = "macOS";
#endif
#ifdef __linux__
    macros += "__linux__ ";
    operating_system = "Linux";
#endif
#ifdef TARGET_OS_EMBEDDED
    macros += "TARGET_OS_EMBEDDED ";
    operating_system = "iOS";
#endif
#ifdef TARGET_IPHONE_SIMULATOR
    macros += "TARGET_IPHONE_SIMULATOR ";
    operating_system = "iOS";
#endif
#ifdef TARGET_OS_IPHONE
    macros += "TARGET_OS_IPHONE ";
    operating_system = "iOS";
#endif
#ifdef TARGET_OS_MAC
    macros += "TARGET_OS_MAC ";
    operating_system = "macOS";
#endif
#ifdef __ANDROID__
    macros += "__ANDROID__ ";
    operating_system = "Android";
#endif
#ifdef __unix__
    macros += "__unix__ ";
    //operating_system = "Unix";
#endif
#ifdef _POSIX_VERSION
    macros += "_POSIX_VERSION ";
    //operating_system = "POSIX";
#endif
#ifdef __sun
    macros += "__sun ";
    operating_system = "Solaris";
#endif
#ifdef __hpux
    macros += "__hpux ";
    operating_system = "HP_UX";
#endif
#ifdef BSD
    macros += "BSD ";
    operating_system = "BSD";
#endif
#ifdef __DragonFly__
    macros += "__DragonFly__ ";
    operating_system = "BSD";
#endif
#ifdef __FreeBSD__
    macros += "__FreeBSD__ ";
    operating_system = "BSD";
#endif
#ifdef __NetBSD__
    macros += "__NetBSD__ ";
    operating_system = "BSD";
#endif
#ifdef __OpenBSD__
    macros += "__OpenBSD__ ";
    operating_system = "BSD";
#endif
    return {operating_system, macros};
}

//extern "C" char *cs_strdup(CSOUND *, const char *);

/**
 * Returns a stringified list of any compiler macros that identify the 
 * operating system, plus a generic name for the operating system.
 */
class CxxOperatingSystem : public csound::OpcodeBase<CxxOperatingSystem>
{
public:
    // OUTPUTS
    STRINGDAT *S_operating_system;
    STRINGDAT *S_macros;
    // INPUTS
    // STATE
    /**
     * This is an i-time only opcode. Everything happens in init.
     */
    int init(CSOUND *csound)
    {
        int result = OK;
        auto results = get_operating_system();
        S_operating_system->data = csound->Strdup(csound, results[0].data());
        S_operating_system->size = std::strlen(S_operating_system->data);
        S_macros->data = csound->Strdup(csound, results[1].data());
        S_macros->size = std::strlen(S_operating_system->data);
        return result;
    };
};

/**
 * Immedidately raises an operating system signal, identified by the string form  
 * of the usual macro constant: 
 * "SIGTERM"	Termination request, sent to the program. This can be used to 
 *              force Csound to exit when otherwise it would hang.
 * "SIGSEGV"	Invalid memory access (segmentation fault).
 * "SIGINT"	    External interrupt, usually initiated by the user. This can 
 *              used when debugging to force Csound to break execution.
 * "SIGILL"	    Invalid program image, such as invalid instruction.
 * "SIGABRT"	Abnormal termination condition, as is e.g. initiated by abort().
 * "SIGFPE"	    Erroneous arithmetic operation, such as divide by zero,
 */
class CxxRaise : public csound::OpcodeBase<CxxRaise>
{
public:
    // OUTPUTS
    // INPUTS
    STRINGDAT *S_signum;
    // STATE
    /**
     * This is an i-time only opcode. Everything happens in init.
     */
    int init(CSOUND *csound)
    {
        std::string signum = S_signum->data;
        if (signum == "SIGTERM") {
            std::signal(SIGTERM, SIG_DFL);
            std::raise(SIGTERM);
        } 
        if (signum == "SIGSEGV") {
            std::signal(SIGSEGV, SIG_DFL);
            std::raise(SIGSEGV);
        } 
        if (signum == "SIGINT") {
            std::signal(SIGINT, SIG_DFL);
            std::raise(SIGINT);
        } 
        if (signum == "SIGILL") {
            std::signal(SIGILL, SIG_DFL);
            std::raise(SIGILL);
        } 
        if (signum == "SIGABRT") {
            std::signal(SIGABRT, SIG_DFL);
            std::raise(SIGABRT);
        } 
        if (signum == "SIGFPE") {
            std::signal(SIGFPE, SIG_DFL);
            std::raise(SIGFPE);
        }         
        return OK;
    };
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
        status += csound->AppendOpcode(csound,
                                          (char *)"cxx_os",
                                          sizeof(CxxOperatingSystem),
                                          0,
                                          1,
                                          (char *)"SS",
                                          (char *)"",
                                          (int (*)(CSOUND*,void*)) CxxOperatingSystem::init_,
                                          (int (*)(CSOUND*,void*)) 0,
                                          (int (*)(CSOUND*,void*)) 0);
        status += csound->AppendOpcode(csound,
                                          (char *)"cxx_raise",
                                          sizeof(CxxRaise),
                                          0,
                                          1,
                                          (char *)"",
                                          (char *)"S",
                                          (int (*)(CSOUND*,void*)) CxxRaise::init_,
                                          (int (*)(CSOUND*,void*)) 0,
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
