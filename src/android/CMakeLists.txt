# OpenSSL support for android
include(FetchContent)
FetchContent_Declare(
  android_openssl
  DOWNLOAD_EXTRACT_TIMESTAMP true
  URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip)
FetchContent_MakeAvailable(android_openssl)
include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)

target_sources(
  YuRadio
  PRIVATE androidkeyboard.h
          androidkeyboard.cpp
          androidmediasessionimageprovider.h
          androidmediasessionimageprovider.cpp
          androidradiocontroller.cpp
          androidradiocontroller.h
          nativemediacontroller.cpp
          nativemediacontroller.h
          notificationclient.cpp
          notificationclient.h
          virtualkeyboardlistener.h
          virtualkeyboardlistener.cpp)
target_include_directories(YuRadio PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
add_android_openssl_libraries(YuRadio)
