set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

qt_add_executable(YuRadio main.cpp)

add_subdirectory(network)
add_subdirectory(YuRadioContents)

if(ANDROID)
  add_subdirectory(android)
endif()

if(LINUX)
  add_subdirectory(linux)
endif()

if(SPOTIFY_CLIENTID
   AND SPOTIFY_SECRET
   AND SPOTIFY_CLIENTID_HASH MATCHES "^(0|[a-fA-F0-9]+)$"
   AND SPOTIFY_SECRET_HASH MATCHES "^(0|[a-fA-F0-9]+)$")
  message("Spotify integration - OK")
else()
  set(SPOTIFY_SECRET_HASH 0)
  set(SPOTIFY_CLIENTID_HASH 0)
endif()

configure_file(applicationconfig.h.in
               "${CMAKE_BINARY_DIR}/config/applicationconfig.h" @ONLY)

target_include_directories(
  YuRadio PUBLIC "$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/config>")

set(basic_controller_sources basicradiocontroller.cpp basicradiocontroller.h)

qt_add_qml_module(
  YuRadio
  URI
  "Main"
  VERSION
  1.0
  QML_FILES
  Main.qml
  ErrorPage.qml
  NO_PLUGIN
  SOURCES
  application.h
  application.cpp
  algorithm.h
  algorithm.cpp
  audiostreamrecorder.h
  audiostreamrecorder.cpp
  downloadspeedmeasurer.h
  downloadspeedmeasurer.cpp
  radioinforeaderproxyserver.h
  radioinforeaderproxyserver.cpp
  radioplayer.h
  radioplayer.cpp
  musicinfomodel.h
  musicinfomodel.cpp
  musicinfoproviderbackend.h
  musicinfoproviderbackend.cpp
  itunesbackend.h
  itunesbackend.cpp
  storage.h
  storage.cpp
  spotifybackend.h
  spotifybackend.cpp
  imageloader.h
  imageloader.cpp
  platformradiocontroller.cpp
  platformradiocontroller.h
  languagetranslator.h
  languagetranslator.cpp
  globalkeylistener.h
  globalkeylistener.cpp
  sqlquerymodel.h
  sqlquerymodel.cpp
  radiostation.h
  radiostation.cpp
  radiostationmodel.h
  radiostationmodel.cpp
  logging.h
  logging.cpp
  obf.h
  obf.cpp
  memoryliterals.h
  "$<$<NOT:$<PLATFORM_ID:Android>>:${basic_controller_sources}>"
  DEPENDENCIES
  network)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1. If
# you are developing for iOS or macOS you should consider setting an explicit,
# fixed bundle identifier manually though.
set_target_properties(
  YuRadio
  PROPERTIES # MACOSX_BUNDLE_GUI_IDENTIFIER com.example.YuRadio
             MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
             MACOSX_BUNDLE_SHORT_VERSION_STRING
             ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
             MACOSX_BUNDLE TRUE
             WIN32_EXECUTABLE TRUE
             QT_ANDROID_PACKAGE_SOURCE_DIR ${PROJECT_SOURCE_DIR}/android)

target_link_libraries(
  YuRadio
  PRIVATE Qt6::Core
          Qt6::Gui
          Qt6::Qml
          Qt6::Quick
          Qt6::QuickControls2
          Qt6::Sql
          Qt6::Positioning
          Qt6::Location
          Qt6::NetworkAuth
          Qt6::Svg
          YuRadioNetworkplugin
          YuRadioContentsplugin
          "$<$<NOT:$<PLATFORM_ID:Android>>:Qt6::Widgets>"
          "$<$<NOT:$<PLATFORM_ID:Android>>:Qt6::Multimedia>"
          "$<TARGET_NAME_IF_EXISTS:uiohook>"
          "$<TARGET_NAME_IF_EXISTS:HotReloader>")

target_set_warnings(YuRadio)
