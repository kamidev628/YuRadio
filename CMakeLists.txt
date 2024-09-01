cmake_minimum_required(VERSION 3.22)

include(cmake/CompilerWarnings.cmake)
include(cmake/VersionConfig.cmake)
include(CMakeDependentOption)

project(YuRadio VERSION ${YURADIO_VERSION_CANONICAL})

find_package(Qt6 REQUIRED COMPONENTS Core)

qt_standard_project_setup(REQUIRES 6.5 I18N_TRANSLATED_LANGUAGES en ru)

cmake_dependent_option(
  BUILD_UIOHOOK
  "Build the uiohook library(enables media key support for desktop platforms)"
  ON "LINUX OR WIN32 OR APPLE" OFF)

if(BUILD_UIOHOOK)
  add_compile_definitions(YuRadio PRIVATE UIOHOOK_SUPPORTED)
endif()

add_subdirectory(deps)
add_subdirectory(hotreloader)
add_subdirectory(src)

if(WIN32)
  set(app_icon_resource_windows "resources/windows/yuradio.rc")
  configure_file("resources/windows/yuradio.rc.in" ${app_icon_resource_windows})
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

if(LINUX
   OR WIN32
   OR APPLE)
  install(
    TARGETS YuRadio
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT YuRadioInstaller)
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
endif()

# NOTE: Must specify CPACK_IFW_ROOT otherwise cmake will not find
# C:/Qt6/Tools/QtInstallerFramework/4.8

set(CPACK_GENERATOR IFW)
set(CPACK_IFW_VERBOSE ON)

set(CPACK_PACKAGE_NAME "YuRadio")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Cross-platform online radio player")
set(CPACK_PACKAGE_VERSION "${YURADIO_VERSION_CANONICAL}")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "${CPACK_PACKAGE_NAME}")
set(CPACK_COMPONENTS_ALL YuRadioInstaller)

set(CPACK_IFW_PACKAGE_START_MENU_DIRECTORY "YuRadio")
set(CPACK_IFW_PACKAGE_NAME "YuRadio")
set(CPACK_IFW_PACKAGE_TITLE "YuRadio Installer")
set(CPACK_IFW_PACKAGE_PUBLISHER "Yunag")
set(CPACK_IFW_PACKAGE_WIZARD_SHOW_PAGE_LIST ON)
set(CPACK_IFW_PACKAGE_WIZARD_STYLE Classic)

set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")

include(CPack)
include(CPackIFW)

cpack_add_component(YuRadioInstaller DISPLAY_NAME "YuRadio")

cpack_ifw_configure_component(
  YuRadioInstaller FORCED_INSTALLATION
  NAME YuRadioInstaller
  VERSION ${YURADIO_VERSION_CANONICAL}
  LICENSES "GPL License" ${CPACK_RESOURCE_FILE_LICENSE}
  DEFAULT TRUE)
