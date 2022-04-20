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

The `cxx_invoke` opcode enables an opcode-like invocable interface to be 
created and called during the Csound performance, either at init time, or 
at k-rate. Commonly, this is used to implement new Csound opcodes directly in 
C++ from the Csound orchestra. It is also used to generate scores or control 
channel values at the beginning of, or during, the performance.

These opcodes do not embed the C++ compiler, but rather use the operating 
system and an installed C++ toolchain to execute a C++ compilation. The 
resulting dynamic link libraries are then loaded by Csound and symbols in them 
can be invoked by Csound.

@@include[doc/cxx_compile.md](doc/cxx_compile.md)

@@include[doc/cxx_invoke.md](doc/cxx_invoke.md)

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
