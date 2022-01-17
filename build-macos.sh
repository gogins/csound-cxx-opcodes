#!/bin/bash
rm clang_opcodes.so
export CLANGLIBS2="-lclangTooling -lclangFrontendTool -lclangFrontend -lclangDriver -lclangSerialization -lclangCodeGen -lclangParse -lclangSema -lclangStaticAnalyzerFrontend -lclangStaticAnalyzerCheckers -lclangStaticAnalyzerCore -lclangAnalysis -lclangARCMigrate -lclangRewrite -lclangRewriteFrontend -lclangEdit -lclangAST -lclangASTMatchers -lclangLex -lclangBasic -lclang"
clang++ -v -Xlinker -g -O2 -fPIC -Wl,-export-dynamic -shared `/opt/homebrew/Cellar/llvm@12/12.0.1_1/bin/llvm-config --cxxflags --ldflags` -I/usr/local/include -I/usr/local/include/csound -I/Users/michaelgogins//Library/Frameworks/CsoundLib64.framework/Headers clang_opcodes.cpp $CLANGLIBS2 `/opt/homebrew/Cellar/llvm@12/12.0.1_1/bin/llvm-config --libs --system-libs` -o clang_opcodes.so
ls -ll
csound --opcode-lib="./clang_opcodes.so" clang_hello.csd
