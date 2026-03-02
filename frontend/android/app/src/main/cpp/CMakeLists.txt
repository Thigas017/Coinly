cmake_minimum_required(VERSION 3.22.1)
project(core_ai)

#Locate OpenCV using the path provided in the Gradle configuration
find_package(OpenCV REQUIRED)

#Create the shared library from the C++ source file
add_library(core_ai SHARED native_lib.cpp)

#Link the library against OpenCV and Android log system
target_link_libraries(core_ai ${OpenCV_LIBS} log)