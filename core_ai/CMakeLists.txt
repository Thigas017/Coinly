cmake_minimum_required(VERSION 4.0)
project(core_ai)

set(CMAKE_CXX_STANDARD 17)

set(OpenCV_DIR "C:/opencv/build")
find_package(OpenCV REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})

add_executable(core_ai main.cpp)

target_link_libraries(core_ai ${OpenCV_LIBS})
