cmake_minimum_required(VERSION 3.16)
project(csound_cxx_opcodes)

include(ExternalProject)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_VERBOSE_MAKEFILE ON)
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -Wall")
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME "csound-cxx")
# add_compile_options("-Wno-multichar")
include_directories(".")
include_directories("${CMAKE_SOURCE_DIR}")
include_directories("${CMAKE_SOURCE_DIR}/csound/interfaces")
include_directories("${CMAKE_SOURCE_DIR}/csound/include")

set(APIVERSION "6.0")
set(CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/local-linux")
set(CMAKE_BUILD_TYPE "RelWithDebInfo")
set(ALLOW_DUPLICATE_CUSTOM_TARGETS "Yes")
add_compile_definitions(USE_DOUBLE)
if(MSVC)
    # Required to make __cplusplus define the correct value:
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zc:__cplusplus")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17")
    # To verify the above has worked:
    # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zc:preprocessor")
    # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /PD")
endif(MSVC)
set(USE_DOUBLE "Yes")
set(BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR})
set(BUILD_PLUGINS_DIR ${BUILD_DIR})
set(BUILD_BIN_DIR ${BUILD_DIR})
set(BUILD_LIB_DIR ${BUILD_DIR})
set(EXECUTABLE_INSTALL_DIR "bin")
set(SHARE_INSTALL_DIR "share/csound-cxx")
option(USE_LIB64 "Set to on to set installation directory for libraries to lib64" OFF)
if(USE_LIB64)
    set(LIBRARY_INSTALL_DIR "lib64")
    add_definitions("-DLIB64")
else()
    set(LIBRARY_INSTALL_DIR "lib")
endif()

set(PLUGIN_INSTALL_DIR "${LIBRARY_INSTALL_DIR}/csound/plugins64-${APIVERSION}")
option(USE_LRINT "Use lrint/lrintf for converting floating point values to integers." ON)
set(CMAKE_SKIP_RPATH True)

message(STATUS "BUILD_BIN_DIR:                  ${BUILD_BIN_DIR}")
message(STATUS "BUILD_LIB_DIR:                  ${BUILD_LIB_DIR}")
message(STATUS "BUILD_PLUGINS_DIR:              ${BUILD_PLUGINS_DIR}.")
message(STATUS "LIBRARY INSTALL DIR:            ${LIBRARY_INSTALL_DIR}")
message(STATUS "PLUGIN_INSTALL_DIR:             ${PLUGIN_INSTALL_DIR}")
message(STATUS "SHARE_INSTALL_DIR:              ${SHARE_INSTALL_DIR}")
message(STATUS "CMAKE_INSTALL_PREFIX:           ${CMAKE_INSTALL_PREFIX}")
message(STATUS "CPACK_PACKAGING_INSTALL_PREFIX: ${CPACK_PACKAGING_INSTALL_PREFIX}")

add_library(csound_cxx SHARED cxx_opcodes.cpp)
set_target_properties(csound_cxx PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${BUILD_BIN_DIR}
    LIBRARY_OUTPUT_DIRECTORY ${BUILD_LIB_DIR}
    ARCHIVE_OUTPUT_DIRECTORY ${BUILD_LIB_DIR}
    )
target_include_directories(csound_cxx PUBLIC 
    "." 
    "${CMAKE_SOURCE_DIR}/csound/interfaces"
    "${CMAKE_SOURCE_DIR}/csound/include")
if(APPLE)
    target_link_libraries(csound_cxx PRIVATE "-framework Cocoa")
endif()
install(TARGETS csound_cxx
    LIBRARY DESTINATION ${PLUGIN_INSTALL_DIR})

# These are the real targets: the packages.

# distro codename
# find stuff we need
find_program(LSB_RELEASE_CMD lsb_release)
if(NOT DISTRO_CODENAME)
  if(NOT LSB_RELEASE_CMD)
    message(WARNING "DEB Generator: Can't find lsb_release in your path. Setting DISTRO_CODENAME to unknown.")
    set(DISTRO_CODENAME unknown)
  else()
    execute_process(COMMAND ${LSB_RELEASE_CMD} -cs
                    OUTPUT_VARIABLE DISTRO_CODENAME
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  endif()
endif()

set(CPACK_COMPONENTS_ALL csound-cxx)
set(CPACK_COMPONENTS_ALL_IN_ONE_PACKAGE "ON")
set(CPACK_GENERATOR ZIP)
set(CPACK_PACKAGE_CONTACT "${CPACK_DEBIAN_PACKAGE_MAINTAINER}")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_SOURCE_DIR}/README.md")
set(CPACK_PACKAGE_NAME "csound-cxx-opcodes")
set(CPACK_PACKAGE_VERSION "1.2.0")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README.md")

set(CPACK_DEBIAN_ARCHITECTURE ${CMAKE_SYSTEM_PROCESSOR})
set(CPACK_DEBIAN_COMPONENT_INSTALL "ON")   
#set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${CMAKE_SOURCE_DIR}/DEBIAN/triggers")
set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "Enable Csound to compile, load, link, and run C++ code embedded in the Csound orchestra at run time, including for user-defined opcodes.")
set(CPACK_DEBIAN_PACKAGE_ENHANCES "csound, libsound64-dev, csound-python, csoundqt")
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS "ON")
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS_POLICY ">=")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://michaelgogins.tumblr.com/csound_extended")
set(CPACK_DEBIAN_PACKAGE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Michael Gogins <michael.gogins@gmail.com>")
set(CPACK_DEBIAN_PACKAGE_NAME "${CPACK_PACKAGE_NAME}")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS "ON")

install(FILES ${CMAKE_SOURCE_DIR}/LICENSE
    DESTINATION share/doc/${CPACK_DEBIAN_PACKAGE_NAME})
install(DIRECTORY ${CMAKE_SOURCE_DIR}/examples
    DESTINATION share/doc/${CPACK_DEBIAN_PACKAGE_NAME})
install(DIRECTORY ${CMAKE_SOURCE_DIR}/doc
    DESTINATION share/doc/${CPACK_DEBIAN_PACKAGE_NAME})

include (CPack)
