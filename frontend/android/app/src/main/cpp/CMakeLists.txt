cmake_minimum_required(VERSION 3.10.2)
project(core_ai)

#Instruct Android to compile the test source file into a shared .so library
add_library(core_ai SHARED native_lib.cpp)