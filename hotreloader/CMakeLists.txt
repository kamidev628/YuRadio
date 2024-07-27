cmake_minimum_required(VERSION 3.16)

project(
  HotReloader
  VERSION 0.1
  LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Network WebSockets Quick HttpServer)

add_library(
  HotReloader
  hotreloaderserver.h hotreloaderserver.cpp hotreloaderclient.h
  hotreloaderclient.cpp hotreloaderurlinterceptor.h
  hotreloaderurlinterceptor.cpp)

target_include_directories(HotReloader PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(HotReloader Qt6::Core Qt6::Network Qt6::WebSockets
                      Qt6::Quick Qt6::HttpServer)

add_executable(HotReloaderServer server.cpp)
target_link_libraries(HotReloaderServer PRIVATE HotReloader)

target_set_warnings(HotReloader)
target_set_warnings(HotReloaderServer)
