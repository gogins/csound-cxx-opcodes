cmake_minimum_required (VERSION 3.4.3)
project(cxx-opcodes)
# Useful information.
message(STATUS "CMAKE_SYSTEM_NAME: ${CMAKE_SYSTEM_NAME}")
message(STATUS "CMAKE_HOST_SYSTEM_NAME: ${CMAKE_HOST_SYSTEM_NAME}")    
message(STATUS "CMAKE_CURRENT_SOURCE_DIR: ${CMAKE_CURRENT_SOURCE_DIR}")    
if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    message(STATUS "CMAKE_FRAMEWORK_PATH: ${CMAKE_FRAMEWORK_PATH}")
    message(STATUS "CMAKE_SYSTEM_FRAMEWORK_PATH: ${CMAKE_SYSTEM_FRAMEWORK_PATH}")
    message(STATUS "HOMEBREW_PREFIX: $ENV{HOMEBREW_PREFIX}")
endif()

# Global CMake configuration.
set(CMAKE_CXX_STANDARD 17)
if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    set(APP_PROPERTIES
        LINK_FLAGS "/SUBSYSTEM:console"
    )
    set(SMTG_USE_STDATOMIC_H OFF CACHE BOOL “” FORCE)
endif()

# Target-specific configuration.
add_library(cxx_opcodes
    MODULE
    "cxx_opcodes.cpp")
target_include_directories(cxx_opcodes PRIVATE 
    "${CMAKE_CURRENT_SOURCE_DIR}/csound/include"
    ".")
if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    target_compile_options(cxx_opcodes PRIVATE "-fobjc-arc")
endif()

