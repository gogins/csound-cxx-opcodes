csound-cxx-opcodes                         {#mainpage}
==================
![GitHub All Releases (total)](https://img.shields.io/github/downloads/gogins/clang-opcodes/total.svg)<br>

Michael Gogins<br>
https://github.com/gogins<br>
http://michaelgogins.tumblr.com

The CXX opcodes provide a means for Csound users to embed C++ source code 
in Csound orchestra code, and for Csound then to compile, load, link, and run 
this C++ code during the course of the Csound performance.

This could of course be done outside of Csound, e.g. by writing plugin 
opcodes. However, experience shows that bringing the C++ code and build 
commands into Csound provides a _considerably_ more efficient composing 
environment.

The `cxx_compile` opcode compiles C++ source, embedded in a Csound 
orchestra, into a dynamic link library, and executes its entry point at init 
time.

The `cxx_invoke` opcode implements an opcode-like invocable interface to be 
created and called during the Csound performance, either at init time, or 
at k-rate. Commonly, this is used to implement new Csound opcodes directly in 
C++ from the Csound orchestra. It is also used to generate scores or control 
channel values at the beginning of, or during, the performance.

These opcodes do not embed the C++ compiler, but rather use the operating 
system and an installed C++ toolchain to execute a C++ compilation. The 
resulting dynamic link libraries are then loaded by Csound, and symbols in them 
can be invoked by Csound.

# cxx_compile

`cxx_compile` - Compile C++ source code into a dynamic link library, and 
execute its entry point at Csound init time. 

## Description

The `cxx_compile` opcode uses an installed C++ toolchain to compile C++ source 
code that is embedded in the orchestra at Csound's init time. The code is 
compiled to a dynamic link library that is then linked and loaded. A specified 
entry point is then called. This function can do anything that C++ code can do 
and has access to the running instance of Csound.

## Syntax
```
i_result cxx_compile S_entry_point, S_source_code, S_compiler_command [, S_dynamic_link_libraries]
```
## Initialization

*S_entry_point* - A valid C identifier, unique in the Csound performance, 
for an entry point function that must be defined in the source code. This 
function must have the signature `extern "C" int (*)(CSOUND *csound)`. This 
function has full access to the running instance of Csound via the Csound API 
members of the CSOUND structure, as well as to all symbols in all other loaded 
dynamic link libraries.

*S_source_code* - C++ source code. Can be a multi-line string literal 
enclosed in `{{` and `}}`. Please note, this string is a "heredoc" and, thus, 
any `\` characters in it must be escaped, e.g. one must write `\\n` not `\n` 
for a newline character. The source code represents one translation unit, but 
it can be as large as needed; in practice, this is not a limitation.

*S_compiler_command* - Standard gcc/clang compiler command, as would be passed 
on the terminal command line. Can be a multi-line string literal enclosed in 
`{{` and `}}`. If the `-v` option is present, additional diagnostics are 
enabled for the `cxx_compile` and `cxx_invoke` opcodes. Link libraries and 
linker options should also be specified normally. The compiler name must come 
first, this enables these opcodes to be used with different compilers. The 
source code filename and the output filename must not be specified.

*i_result* - 0 if the code has been compiled and executed succesfully; 
non-0 if there is an error. Toolchain diagnostics are printed to stderr.

*S_dynamic_link_libraries* - A space-delimited list of dynamic link libraries 
upon which the compiled code depends, and which therefore must be preloaded. 
These libraries must be complete filenames (e.g., not `-lmylib`, but 
`libMylib.so`), searched for in the standard locations, or can be given as 
complete filepaths to be loaded unconditionally.

## Performance

The module is compiled and executed at Csound's initialization time, which 
comes after `csoundStart` has been called. If the compilation is done in the 
orchestra header, i.e. in `instr 0`, the execution occurs during Csound's 
init pass for `instr 0`. If the compilation is done from a regular Csound 
instrument, the execution occurs during Csound's init pass for that particular 
instrument instance.

Non-standard include directories and compiler options may be used, but must be 
defined in `S_compiler_command`.

Dynamic link libraries on which the module depends may also be used, and may 
be specified in the normal way.

The source code is saved to a unique temporary file and then compiled, loaded, 
linked, and executed.

__**PLEASE NOTE**__: Some shared libraries use the symbol `__dso_handle`, but 
this is not always defined in the compiler's startup code. To work around this, 
manually define it in your C++ code like this:
```
void* __dso_handle = (void *)&__dso_handle;
```
The module _must_ define a uniquely named C function, which is the entry point 
to the module, in the same way that the `main` function is the entry point to 
a C program, with the following signature:
```
extern "C" int(*)(CSOUND *csound);
```
Once the `cxx_compile` opcode has preloaded any dependent libraries, and then 
compiled, linked, and loaded the module, Csound immediately calls the entry
point function in that module. 

The entry point function may call any Csound API functions that are members of 
the `CSOUND` struct, define classes and structs, call any public symbol in any 
loaded dynamic link library, or indeed do anything at all that can be done 
with C++ code.

For example, the module may use an external shared library to assist with 
algorithmic composition, then translate the generated score to a Csound score, 
then call `csound->InputMessage` to schedule the score for immediate 
performance.

However, one of the most significant uses of `cxx_compile` is to compile C++
code into classes that can perform the work of Csound opcodes. This is 
done by implementing the `CxxInvokable` interface. See `cxx_invoke` for how 
this works and how to use it.

# cxx_os

`cxx_os` - Returns two strings, the first identifying the operating system 
targeted by the compiler, and the second listing the compiler macros that 
were defined by the compiler.

## Description

The `cxx_os` opcode returns two strings, the first identifying the operating 
system targeted by the compiler, and the second listing the compiler macros 
that are defined by the compiler. This can be used for conditionally executing 
different code in the Csound orchestra depending on the operating system. 
That, in turn, can be used to write orchestras that work without modification 
on different operating systems.

## Syntax
```
S_os, S_macros cxx_os
```

## Example

The `cxx_hello.csd` file uses the `cxx_os` opcode to print the operating 
system name and a list of compiler macros that identify the operating system.

The operating system name in turn is used to execute an appropriate compiler 
command for that operating system.

# cxx_raise

`cxx_raises` - Immediately raises the specified operating system signal.

## Description

The `cxx_raise`  opcode  immediately raises an operating system signal, 
identified by the string form of the usual macro constant: 

"SIGTERM" - Termination request, sent to the program. This can be used to 
force Csound to exit, when otherwise it would hang.

"SIGSEGV" - Invalid memory access (segmentation fault).

"SIGINT" - External interrupt, usually initiated by the user. This can 
be used when debugging, to force Csound to break execution.

"SIGILL" - Invalid program image, such as invalid instruction.

"SIGABRT" - Abnormal termination condition, as is e.g. initiated by abort().

"SIGFPE" - Erroneous arithmetic operation, such as divide by zero,

## Syntax
```
cxx_raise S_signal_name
```

# Installation

1. Install the C++ toolchain of your preference.

2. Either download a binary release of these opcodes for your system, or 
   compile them from source code using:
   ```
   cmake .
   make
   ```
   
3. Copy the `cxx_opcodes.so` file to your `OPCODE6DIR6` directory, or load 
   it with Csound's `--opcode-lib="./cxx_opcodes.so"` option.
   
4. Test by executing `csound cxx_example.csd`. 

# Credits

Michael Gogins<br>
https://github.com/gogins<br>
http://michaelgogins.tumblr.com
