cmake_minimum_required(VERSION 3.20)

find_package(Qt6 REQUIRED COMPONENTS Core DBus)

add_library(
  qtmpris
  mpris.cpp
  mprisrootadaptor.cpp
  mprisplayeradaptor.cpp
  mprisplayer.cpp
  mpriscontroller.cpp
  mprismanager.cpp
  mprisplayerinterface.cpp
  mprisrootinterface.cpp
  mprisqt.h
  mpris.h
  mprisplayer.h
  mprisplayer_p.h
  mpriscontroller.h
  mpriscontroller_p.h
  mprismanager.h
  dbusextendedabstractinterface.cpp
  dbusextendedpendingcallwatcher.cpp
  dbusextended.h
  dbusextendedabstractinterface.h
  dbusextendedpendingcallwatcher_p.h)

target_link_libraries(qtmpris PUBLIC Qt6::Core Qt6::DBus)
# TODO: Separate PRIVATE and PUBLIC headers
target_include_directories(qtmpris PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
