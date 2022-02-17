# CXX Opcodes
![GitHub All Releases (total)](https://img.shields.io/github/downloads/gogins/clang-opcodes/total.svg)<br>

Michael Gogins<br>
https://github.com/gogins<br>
http://michaelgogins.tumblr.com

The CXX opcodes provide a means for Csound users to embed C++ source code 
in Csound orchestra code, and for Csound then to compile, load, link, and run 
C++ during the course of the Csound performance.

This could of course be done outside of Csound, e.g. by writing plugin 
opcodes. However, experience shows that bringing the C++ code and build 
commands into Csound provides a _considerably_ more efficient composing 
environment.

The `cxx_compile` opcode compiles C++ source, embedded in a Csound 
orchestra, into a dynamic link library, and executes its entry point at init 
time.

The `cxx_invoke` opcode enables an opcode-like invocable interface to be 
created and called code during the Csound performance, either at init time, or 
at k-rate. Commonly, this is used to implement new Csound opcodes directly in 
C++ from the Csound orchestra. It is also used to generate scores or control 
channel values at the beginning of, or during, the performance.

These opcodes do not embed the C++ compiler, but rather use the operating 
system and an installed C++ toolchain to execute a C++ compilation. The 
resulting dynamic link libraries are then loaded by Csound and symbols in them 
can then be invoked by Csound.

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
i_result cxx_compile S_entry_point, S_source_code, S_compiler_options
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
any `\` characters in it must be escaped, e.g. one must write `\\n` not '\n' 
for a newline character. The source code represents one translation unit, but 
it can be as large as needed.

*S_compiler_options* - Standard gcc/clang compiler options, as would be passed 
on the compiler command line. Can be a multi-line string literal enclosed in 
`{{` and `}}`. If the `-v` option is present, additional diagnostics are 
enabled for the `cxx_compile` and `cxx_invoke` opcodes. Link libraries and 
linker options should also be specified normally.

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
defined in `S_compiler_options`.

Dynamic link libraries on which the module depends may also be used, and may 
be specified in the normal way.

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

# cxx_invoke

`cxx_invoke` - creates an instance of a class that implements the 
`CxxInvokable` interface that has been defined previously using 
`cxx_compile`, and invokes that instance at i-time, k-time, or both.

## Description

Creates an instance of a `CxxInvokable` that has been defined previously 
using `cxx_compile`, and invokes that instance at i-time, k-time, or both. 

This can be used to implement any type of Csound opcode. It can also be used 
for other purposes, e.g. simply as a way to call some function in the 
`CxxInvokable` module.

## Syntax
```
[m_output_1,...] cxx_invoke S_cxx_invokeable, i_thread, [, m_input_1,...]
```
## Initialization

*S_cxx_invokable* - A name unique in the Csound performance for a factory 
function `CxxInvokable *(*)` that creates and returns a new object 
implementing the following pure abstract interface:
```
/**
 * Defines the pure abstract interface, implemented by CXX modules, to be 
 * called by Csound using the `cxx_invoke` opcode.
 */
struct CxxInvokable {
	virtual ~CxxInvokable() {};
	/**
	 * Called once at init time. The inputs are the same as the 
	 * parameters passed to the `cxx_invoke` opcode. The outputs become 
	 * the values returned from the `cxx_invoke` opcode. Performs the 
	 * same work as `iopadr` in a standard Csound opcode definition. The 
	 * `opds` argument can be used to find many things about the invoking 
	 * opcode, its enclosing instrument, and the running instance of Csound.
	 */
	virtual int init(CSOUND *csound, OPDS *opds, MYFLT **outputs, MYFLT **inputs) = 0;
	/**
	 * Called once every kperiod. The inputs are the same as the 
	 * parameters passed to the `cxx_invoke` opcode. The outputs become 
	 * the values returned from the `cxx_invoke` opcode. Performs the 
	 * same work as `kopadr` in a standard Csound opcode definition.
	 */
	virtual int kontrol(CSOUND *csound, MYFLT **outputs, MYFLT **inputs) = 0;
	/**
	 * Called by Csound when the Csound instrument that contains this 
	 * instance of the `CxxInvokable` is turned off.
	 */
	virtual int noteoff(CSOUND *csound) = 0;
};
```
*i_thread* - The "thread" on which this `CxxInvokable` will run:

-  1 = The `CxxInvokable::init` method is called, but not the 
   `CxxInvokable::kontrol` method.
-  2 = The `CxxInvokable::init` function is not called, but the
   `CxxInvokable::kontrol` method is called once for every 
   kperiod during the lifetime of the instrument.
-  3 = The `CxxInvokable::init` method is called once at the 
   init pass for the instrument, and the `CxxInvokable::kontrol` 
   method is then called once every kperiod during the lifetime of the 
   instrument.

*[m_input_i,...]* - 0 or more Csound variables, of any type, size, shape, or 
rate, as defined in [entry1.c](https://github.com/csound/csound/blob/develop/Engine/entry1.c). 
These are actually the input arguments provided by the Csound runtime to `cxx_invoke`.

*[m_output_1,...]* - From 0 to 40 Csound variables, of any type, size, 
shape, or rate. These are actually the output arguments provided by the Csound 
runtime for `cxx_invoke`.

The *S_cxx_invokeable* symbol is looked up in the loaded dynamic link library, 
and a new instance of the `CxxInvokable` class is created. `cxx_invoke` then 
calls the `CxxInvokable::init` method with the input and output arguments, and 
any output values computed by the `CxxInvokable` are returned in the elements 
of the *outputs* argument.

Because of the variable numbers and types of arguments, it is virtually 
impossible for `cxx_invoke` to perform type checking at compile time. The user 
must therefore take care to defie the correct numbers, types, shapes, and 
rates for these parameters and return values. 

## Performance

If the `thread` parameter is 2 or 3, the `CxxInvokable::kontrol` method is 
called once per kperiod during the lifetime of the opcode. Any output values 
computed by the `CxxInvokable` must be returned in elements of the *outputs* 
argument.

When the Csound instrument that has created the `cxx_invoke` opcode is 
turned off, Csound calls the `CxxInvokable::noteoff` method. At that 
time, the `CxxInvokable` should release any system resources or memory 
that it has acquired.

The `CxxInvokable` instance is then deleted by the `cxx_invoke` opcode.

An opcode written in C++ for the CXX opcodes should run at the same speed 
as the same code running as a statically compiled plugin opcode, which is 
usually about 2 to 3 times faster than the same algorithm implemented in the 
Csound orchestra language.

## Example

The `cxx_example.csd` file uses the `cxx_compile` opcode to 
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

1. Install the C++ toolchain of your preference.

2. Compile the `cxx_opcodes.cpp` file using `build.sh`, which you may need to 
   modify for your system.
   
3. Copy the `cxx_opcodes.so` file to your `OPCODE6DIR6` directory, or load 
   it with Csound's `--opcode-lib="./cxx_opcodes.so"` option.
   
4. Test by executing `csound cxx_example.csd`. 

# Credits

Michael Gogins<br>
https://github.com/gogins<br>
http://michaelgogins.tumblr.com
