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
[m_output_1,...] cxx_invoke S_cxx_invokable, i_thread, [, m_input_1,...]
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

The `cxx_example.csd` file uses the `cxx_compile` opcode to compile a reverb 
opcode and instrument and a score generator. For the sake of clarity, although 
all of this code could be implemented in one module, the following separate 
modules are 
defined:

1. A reverb opcode, written in C++, which is then wrapped in a Csound instrument 
   definition.
   
2. A score generating function, written in C++.
   
The Csound orchestra in this piece uses the signal flow graph opcodes to connect 
the guitar instrument to the output instrument, where reverb is applied.

# Credits

Michael Gogins<br>
https://github.com/gogins<br>
http://michaelgogins.tumblr.com
