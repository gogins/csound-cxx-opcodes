#!/bin/bash
echo "This build script assumes the use of llvm@13 installed with homebrew."
rm clang_opcodes.dylib
# To use the bundled libc++ please add the following LDFLAGS:
LDFLAGS="-L/opt/homebrew/opt/llvm/lib -Wl,-rpath,/opt/homebrew/opt/llvm/lib"

#llvm is keg-only, which means it was not symlinked into /opt/homebrew,
#because macOS already provides this software and installing another version in
#parallel can cause all kinds of trouble.

#If you need to have llvm first in your PATH, run:
#  echo 'export PATH="/opt/homebrew/opt/llvm/bin:$PATH"' >> ~/.zshrc
export PATH="/opt/homebrew/cellar/llvm/13.0.0_2/bin/:$PATH"

# For compilers to find llvm you may need to set:
export LDFLAGS="-L/opt/homebrew/cellar/llvm/13.0.0_2/lib"
export CPPFLAGS="-I/opt/homebrew/cellar/llvm/13.0.0_2/include"
export CLANGLIBS2="-lclangTooling -lclangFrontendTool -lclangFrontend -lclangDriver -lclangSerialization -lclangCodeGen -lclangParse -lclangSema -lclangStaticAnalyzerFrontend -lclangStaticAnalyzerCheckers -lclangStaticAnalyzerCore -lclangAnalysis -lclangARCMigrate -lclangRewrite -lclangRewriteFrontend -lclangEdit -lclangAST -lclangASTMatchers -lclangLex -lclangBasic -lclang"
which clang++
clang++ -v -g -O2 -fPIC -shared `/opt/homebrew/cellar/llvm/13.0.0_2/bin/llvm-config --cxxflags --ldflags` -I/usr/local/include -I/usr/local/include/csound -I/Library/Frameworks/CsoundLib64.framework/Headers clang_opcodes.cpp $CLANGLIBS2 `/opt/homebrew/cellar/llvm/13.0.0_2/bin/llvm-config --libs --system-libs` -o clang_opcodes.dylib
ls -ll
csound --opcode-lib="./clang_opcodes.dylib" clang_hello.csd
