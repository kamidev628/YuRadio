cmake_minimum_required(VERSION 3.22)

project(
  YuRadio
  VERSION 0.1
  LANGUAGES CXX)

include(cmake/CompilerWarnings.cmake)

find_package(Qt6 REQUIRED COMPONENTS Core WebSockets HttpServer Quick)

qt_standard_project_setup(REQUIRES 6.5 I18N_TRANSLATED_LANGUAGES en ru)

add_subdirectory(deps)
add_subdirectory(hotreloader)
add_subdirectory(src)

if(WIN32)
  set(app_icon_resource_windows
      "${CMAKE_CURRENT_SOURCE_DIR}/resources/yuradio.rc")
  target_sources(YuRadio PRIVATE ${app_icon_resource_windows})
endif()

qt_add_translations(
  TARGETS
  YuRadio
  YuRadioContents
  TS_FILE_BASE
  YuRadio
  TS_FILE_DIR
  translations
  LUPDATE_OPTIONS
  -no-obsolete)
# NOTE: Don't forget to run `update_translations` target when ts files are
# changed

if(NOT ANDROID)
  install(
    TARGETS YuRadio
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
  # Deployment script for LINUX, MAC, WINDOWS
  qt_generate_deploy_qml_app_script(
    TARGET
    YuRadio
    OUTPUT_SCRIPT
    deploy_script
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM)
  install(SCRIPT ${deploy_script})
endif()
