#!/bin/bash
rm clang_opcodes.dylib
which clang++
clang++ -v -g -O2 -fPIC -shared -I/usr/local/include -I/usr/local/include/csound -I/Library/Frameworks/CsoundLib64.framework/Headers cxx_opcodes.cpp -o cxx_opcodes.dylib
ls -ll
csound --opcode-lib="./cxx_opcodes.dylib" cxx_hello.csd
