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
i_result cxx_compile S_entry_point, S_source_code, S_compiler_command
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
Once the `cxx_compile` opcode has compiled, linked, and loaded the module, 
Csound immediately calls the entry point function in that module. 

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

## Example

The `cxx_hello.csd` file uses the `cxx_compile` opcode to demonstrate and 
test the basic funtionality of the `cxx_compile` and `cxx_invoke` opcodes. 
This is a bare bones test that does just enough to prove that things are 
working, and no more.

ß# Credits

Michael Gogins<br>
https://github.com/gogins<br>
http://michaelgogins.tumblr.com
