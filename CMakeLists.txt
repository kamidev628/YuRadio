cmake_minimum_required(VERSION 3.28...3.30)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(OSConfig)
include(CompilerWarnings)
include(VersionConfig)
include(CMakeDependentOption)

project(YuRadio VERSION ${YURADIO_VERSION_CANONICAL})

# NOTE: Following line required by `qt_generate_deploy_qml_app_script`
find_package(
  Qt6 6.5 REQUIRED
  COMPONENTS Core
             Svg
             Sql
             Qml
             Quick
             QuickControls2
             Multimedia
             ShaderTools
             Positioning
             Location
             LinguistTools
             Widgets
             WebSockets
             NetworkAuth)

qt_standard_project_setup(
  REQUIRES
  6.5
  I18N_TRANSLATED_LANGUAGES
  en
  de
  fr
  ja
  ru)

cmake_dependent_option(
  BUILD_UIOHOOK
  "Build the uiohook library(enables media key support for desktop platforms)"
  ON "LINUX OR WIN32 OR APPLE" OFF)
option(BUILD_HOTRELOADER "Build hotreloader" OFF)

if(BUILD_UIOHOOK)
  add_compile_definitions(YuRadio PRIVATE UIOHOOK_SUPPORTED)
endif()

if(BUILD_HOTRELOADER)
  add_compile_definitions(YuRadio PRIVATE HOTRELOADER_SUPPORTED)
endif()

add_subdirectory(deps)
if(BUILD_HOTRELOADER)
  add_subdirectory(hotreloader)
endif()
add_subdirectory(src)

include(DesktopConfig OPTIONAL)

qt_add_translations(
  TARGETS
  YuRadio
  YuRadioContents
  TS_FILE_BASE
  YuRadio
  TS_FILE_DIR
  translations)
# NOTE: Don't forget to run `update_translations` target when ts files are
# changed

if(LINUX
   OR WIN32
   OR APPLE)
  install(
    TARGETS YuRadio
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT YuRadioInstaller)
endif()

# Deployment script for LINUX, MAC, WINDOWS
qt_generate_deploy_qml_app_script(
  TARGET
  YuRadio
  OUTPUT_SCRIPT
  deploy_script
  MACOS_BUNDLE_POST_BUILD
  NO_UNSUPPORTED_PLATFORM_ERROR
  DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
  DEPLOY_TOOL_OPTIONS
  ${deploy_tool_options_arg})
install(SCRIPT ${deploy_script} COMPONENT YuRadioInstaller)

include(CPackConfig OPTIONAL)
include(CPack)
cpack_add_component(YuRadioInstaller DISPLAY_NAME "YuRadio")
