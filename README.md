# Clang Opcodes
![GitHub All Releases (total)](https://img.shields.io/github/downloads/gogins/clang-opcodes/total.svg)<br>

Michael Gogins<br>
https://github.com/gogins<br>
http://michaelgogins.tumblr.com

The Clang opcodes embed the Clang/LLVM just-in-time C++ compiler into Csound. 
This enables a Csound orchestra to include, compile, and run C++ code as part 
of a Csound performance.

The `clang_compile` opcode compiles C++ source, embedded in a Csound 
orchestra, into an executable module, and executes it at init time.

The `clang_invoke` opcode enables a compiled module to be invoked from Csound 
code during the Csound performance, either at init time, or at k-rate. 
Commonly, this is used to implement new Csound opcodes directly in C++ from 
the Csound orchestra. It is also used to generate scores or control channel 
values at the beginning of, or during, the performance.

The `clang_compile` opcode uses the 
[Clang and LLVM infrastructure](https://llvm.org/), and is based on the 
["Clang C Interpreter Example"](https://github.com/llvm/llvm-project/tree/main/clang/examples/clang-interpreter). 
The `clang_invoke` opcode was inspired by the [Faust](https://csound.com/docs/manual/faustgen.html) 
opcodes.

At this time, only one LLVM context and ORC compiler may exist in a single 
Csound process. The results of running multiple Csound performances from a 
single process, where each instance uses the Clang opcodes, are undefined.

# clang_compile

`clang_compile` - Compile C++ source code into a module, and execute it at
Csound init time. 

## Description

The `clang_compile` opcode is an on-request-compiler (ORC) that enables 
Csound to compile C++ source code, embedded in the Csound orchestra, to 
a module of low-level virtual machine (LLVM) intermediate representation (IR) 
code; load and link that module; and call the Csound API, 
other modules, or dynamic link libraries from that module. The ORC compiler is 
a type of just-in-time (JIT) compiler, in which the actual translation to 
machine language takes place automatically whenever a symbol in the module is 
accessed for the first time from the ORC compiler's LLVM execution session.

## Syntax
```
i_result clang_compile S_entry_point, S_source_code, S_compiler_options [, S_link_libraries]
```
## Initialization

*S_entry_point* - A valid C identifier, unique in the Csound performance, 
for an entry point function that must be defined in the module. This function 
must have the signature `extern "C" int (*)(CSOUND *csound)`. This function 
has full access to the running instance of Csound via the Csound API members 
of the CSOUND structure, as well as to all symbols in other LLVM modules, and 
all exported symbols in all loaded dynamic link libraries.

*S_source_code* - C++ source code. Can be a multi-line string literal 
enclosed in `{{` and `}}`. Please note, this string is a "heredoc" and, thus, 
any `\` characters in it must be escaped, e.g. one must write `\\n` not '\n' 
for a newline character. The source code represents one translation unit, but 
it can be as large as needed.

*S_compiler_options* - Standard gcc/clang compiler options, as would be passed 
on the compiler command line. Can be a multi-line string literal enclosed in 
`{{` and `}}`. If the `-v` option is present, additional diagnostics are 
enabled for the `clang_compile` and `clang_invoke` opcodes.

*S_link_libraries* - Optional space-delimited list of system or user dynamic 
link libraries, serving the same function as `-l` options for a standalone 
compiler. Here, however, each dynamic link library must be specified as a 
fully qualified filepath. Each library will be loaded and linked by LLVM 
before the user's code is JIT compiled. Can be a multi-line string literal 
enclosed in `{{` and `}}`. 

*i_result* - 0 if the code has been compiled and executed succesfully; 
non-0 if there is an error. Clang and LLVM diagnostics are printed to stderr.

## Performance

The module is compiled and executed at Csound's initialization time, which 
comes after `csoundStart` has been called. If the compilation is done in the 
orchestra header, i.e. in `instr 0`, the execution occurs during Csound's 
init pass for `instr 0`. If the compilation is done from a regular Csound 
instrument, the execution occurs during Csound's init pass for that particular 
instrument instance.

Non-standard include directories and compiler options may be used, but must be 
defined in `S_compiler_options`.

Dynamic link libraries on which the module depends may be used, whether system 
libraries or user libraries, but must be specified as fully qualified 
filepaths in `S_link_libraries`. The usual compiler option `-l` does _not_ work 
in this context.

__**PLEASE NOTE**__: Some shared libraries use the symbol `__dso_handle`, but 
this is not defined in the ORC compiler's startup code. To work around this, 
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
Once the `clang_compile` opcode has compiled the module, Csound immediately 
calls the entry point function in that module. At that very time, the LLVM ORC 
compiler will translate the IR code in the module to machine language, perform 
relocations, resolve symbols, and otherwise load and link the module into the 
running Csound process, just like any other C++ module.

The entry point function may call any Csound API functions that are members of 
the `CSOUND` struct, define classes and structs, call any public symbol in any 
loaded dynamic link library, or indeed do anything at all that can be done 
with C++ code.

For example, the module may use an external shared library to assist with 
algorithmic composition, then translate the generated score to a Csound score, 
then call `csound->InputMessage` to schedule the score for immediate 
performance.

However, one of the most significant uses of `clang_compile` is to compile C++
code into classes that can perform the work of Csound opcodes. This is 
done by implementing the `ClangInvokable` interface. See `clang_invoke` for how 
this works and how to use it.

## Example

The `clang_hello.csd` file uses the `clang_compile` opcode to demonstrate and 
test the basic funtionality of the `clang_compile` and `clang_invoke` opcodes. 
This is a bare bones test that does just enough to prove that things are 
working, and no more.

# clang_invoke

`clang_invoke` - creates an instance of a class that implements the 
`ClangInvokable` interface that has been defined previously using 
`clang_compile`, and invokes that instance at i-time, k-time, or both.

## Description

Creates an instance of a `ClangInvokable` that has been defined previously 
using `clang_compile`, and invokes that instance at i-time, k-time, or both. 

This can be used to implement any type of Csound opcode. It can also be used 
for other purposes, e.g. simply as a way to call some function in the 
`ClangInvokable` module.

## Syntax
```
[m_output_1,...] clang_invoke S_clang_invokeable, i_thread, [, m_input_1,...]
```
## Initialization

*S_clang_invokable* - A name unique in the Csound performance for a factory 
function `ClangInvokable *(*)` that creates and returns a new object 
implementing the following pure abstract interface:
```
/**
 * Defines the pure abstract interface, implemented by Clang modules, to be 
 * called by Csound using the `clang_invoke` opcode.
 */
struct ClangInvokable {
	virtual ~ClangInvokable() {};
	/**
	 * Called once at init time. The inputs are the same as the 
	 * parameters passed to the `clang_invoke` opcode. The outputs become 
	 * the values returned from the `clang_invoke` opcode. Performs the 
	 * same work as `iopadr` in a standard Csound opcode definition. The 
	 * `opds` argument can be used to find many things about the invoking 
	 * opcode, its enclosing instrument, and the running instance of Csound.
	 */
	virtual int init(CSOUND *csound, OPDS *opds, MYFLT **outputs, MYFLT **inputs) = 0;
	/**
	 * Called once every kperiod. The inputs are the same as the 
	 * parameters passed to the `clang_invoke` opcode. The outputs become 
	 * the values returned from the `clang_invoke` opcode. Performs the 
	 * same work as `kopadr` in a standard Csound opcode definition.
	 */
	virtual int kontrol(CSOUND *csound, MYFLT **outputs, MYFLT **inputs) = 0;
	/**
	 * Called by Csound when the Csound instrument that contains this 
	 * instance of the `ClangInvokable` is turned off.
	 */
	virtual int noteoff(CSOUND *csound) = 0;
};
```
*i_thread* - The "thread" on which this `ClangInvokable` will run:

-  1 = The `ClangInvokable::init` method is called, but not the 
   `ClangInvokable::kontrol` method.
-  2 = The `ClangInvokable::init` function is not called, but the
   `ClangInvokable::kontrol` method is called once for every 
   kperiod during the lifetime of the instrument.
-  3 = The `ClangInvokable::init` method is called once at the 
   init pass for the instrument, and the `ClangInvokable::kontrol` 
   method is then called once every kperiod during the lifetime of the 
   instrument.

*[m_input_i,...]* - 0 or more Csound variables, of any type, size, shape, or 
rate, as defined in [entry1.c](https://github.com/csound/csound/blob/develop/Engine/entry1.c). 
These are actually the input arguments provided by the Csound runtime to `clang_invoke`.

*[m_output_1,...]* - From 0 to 40 Csound variables, of any type, size, 
shape, or rate. These are actually the output arguments provided by the Csound runtime 
for `clang_invoke`.

The *S_clang_invokeable* symbol is looked up in the LLVM execution session 
of the global ORC compiler, and a new instance of the `ClangInvokable` class 
is created. `clang_invoke` then calls the `ClangInvokable::init` method with 
the input and output arguments, and any output values computed by the 
`ClangInvokable` are returned in the elements of the *outputs* argument.

Because of the variable numbers and types of arguments, it is virtually 
impossible for `clang_invoke` to perform type checking. The user must 
therefore take care to defie the correct numbers, types, shapes, and rates for these 
parameters and return values. 

## Performance

If the `thread` parameter is 2 or 3, the `ClangInvokable::kontrol` method is 
called once per kperiod during the lifetime of the opcode. Any output values 
computed by the `ClangInvokable` must be returned in elements of the *outputs* 
argument.

When the Csound instrument that has created the `clang_invoke` opcode is 
turned off, Csound calls the `ClangInvokable::noteoff` method. At that 
time, the `ClangInvokable` should release any system resources or memory 
that it has acquired.

The `ClangInvokable` instance is then deleted by the `clang_invoke` opcode.

An opcode written in C++ for the Clang opcodes should run about 3 percent 
slower than the same code running as a statically compiled plugin opcode, and 
2 to 3 times faster than the same algorithm implemented in the Csound orchestra 
language.

## Example

The `clang_example.csd` file uses the `clang_compile` opcode to 
compile a guitar opcode and instrument, a reverb opcode and instrument, 
and a score generator. For the sake of clarity, although all of this code 
could be implemented in one module, the following separate modules are 
defined:

1. A physically modelled guitar opcode, written in C++, which is then 
   wrapped in a Csound instrument definition.
   
2. A reverb opcode, written in C++, which is then wrapped in a Csound instrument 
   definition.
   
3. A score generating function, written in C++.
   
The Csound orchestra in this piece uses the signal flow graph opcodes to connect 
the guitar instrument to the output instrument, where reverb is applied.

# Installation

1. Install all available components of Clang and LLVM from the stable branch, 
   see https://apt.llvm.org/.

2. Compile the `clang_opcodes.cpp` file using `build.sh`, which you may need to 
   modify for your system.
   
3. Copy the `clang_opcodes.so` file to your `OPCODE6DIR6` directory, or load 
   it with Csound's `--opcode-lib="./clang_opcodes.so"` option.
   
4. Test by executing `csound clang_example.csd`. 

# Credits

Michael Gogins<br>
https://github.com/gogins<br>
http://michaelgogins.tumblr.com
