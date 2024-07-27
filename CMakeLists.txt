cmake_minimum_required(VERSION 3.20)

project(
  YuRadio
  VERSION 0.1
  LANGUAGES CXX)

include(cmake/CompilerWarnings.cmake)

find_package(Qt6 REQUIRED COMPONENTS Core WebSockets HttpServer)
qt_standard_project_setup(REQUIRES 6.5)

add_subdirectory(src)
add_subdirectory(hotreloader)
