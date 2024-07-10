qt_add_executable(YuRadio main.cpp)

set_source_files_properties(AppSettings.qml PROPERTIES QT_QML_SINGLETON_TYPE
                                                       true)
set_source_files_properties(Utils.qml PROPERTIES QT_QML_SINGLETON_TYPE true)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set_target_properties(YuRadio PROPERTIES AUTOMOC ON AUTORCC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Qml Quick QuickControls2
                                         Multimedia ShaderTools)

qt_add_qml_module(
  YuRadio
  URI
  Main
  VERSION
  1.0
  NO_PLUGIN
  QML_FILES
  Main.qml
  App.qml
  RadioDrawer.qml
  ErrorPage.qml
  AppSettings.qml
  Utils.qml
  RadioStationDelegate.qml
  RadioBottomBar.qml
  RadioBottomBarDrawer.qml
  RadioStationsView.qml
  ClickableLink.qml
  SearchBar.qml
  IconButton.qml
  MomentumAnimation.qml
  FakeFlickable.qml
  radiobrowser.mjs
  SOURCES
  restpagination.h
  restpagination.cpp
  limitpagination.h
  limitpagination.cpp
  pagepagination.h
  pagepagination.cpp
  network.h
  network.cpp
  icecastreader.h
  icecastreader.cpp
  circularbuffer.h
  circularbuffer.cpp
  radioplayer.h
  radioplayer.cpp
  musicinfoprovider.h
  musicinfoprovider.cpp
  itunesmusicinfoprovider.h
  itunesmusicinfoprovider.cpp
  musicinfo.h
  musicinfo.cpp
  json.h
  json.cpp
  networkerror.h
  imageloader.h
  imageloader.cpp
  abstractrestmodel.h
  abstractrestmodel.cpp
  jsonrestlistmodel.h
  jsonrestlistmodel.cpp
  RESOURCES
  images/search.svg
  images/trash.svg
  images/menu.svg
  images/github-mark.svg
  images/github-mark-white.svg
  images/profile-picture.jpg
  images/radio.png
  images/plus.svg
  images/play.svg
  images/pause.svg
  images/about.svg
  images/todo.svg
  images/filter.svg
  images/sort.svg)

qt_add_shaders(
  YuRadio
  "shaders"
  BATCHABLE
  PRECOMPILE
  OPTIMIZED
  PREFIX
  /
  FILES
  "shaders/RoundImage.frag")

# OpenSSL support for android
if(ANDROID)
  include(FetchContent)
  FetchContent_Declare(
    android_openssl
    DOWNLOAD_EXTRACT_TIMESTAMP true
    URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip)
  FetchContent_MakeAvailable(android_openssl)
  include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
endif()

if(ANDROID)
  target_sources(YuRadio PRIVATE androidkeyboard.h androidkeyboard.cpp)
  add_android_openssl_libraries(YuRadio)
endif()

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
          Qt6::Multimedia
          HotReloader)

target_set_warnings(YuRadio)

include(GNUInstallDirs)
install(
  TARGETS YuRadio
  BUNDLE DESTINATION .
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
