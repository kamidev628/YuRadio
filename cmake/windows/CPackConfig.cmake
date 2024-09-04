include_guard(GLOBAL)

include(CPackCommon)

# NOTE: Must specify CPACK_IFW_ROOT otherwise cmake will not find
# C:/Qt6/Tools/QtInstallerFramework/4.8
set(CPACK_GENERATOR IFW)

set(CPACK_IFW_VERBOSE ON)
set(CPACK_IFW_PACKAGE_START_MENU_DIRECTORY "YuRadio")
set(CPACK_IFW_PACKAGE_NAME "YuRadio")
set(CPACK_IFW_PACKAGE_TITLE "YuRadio Installer")
set(CPACK_IFW_PACKAGE_PUBLISHER "yunag")
set(CPACK_IFW_PACKAGE_WIZARD_SHOW_PAGE_LIST ON)
set(CPACK_IFW_PACKAGE_WIZARD_STYLE Classic)

include(CPackIFW)
cpack_ifw_configure_component(
  YuRadioInstaller FORCED_INSTALLATION
  NAME YuRadioInstaller
  VERSION ${YURADIO_VERSION_CANONICAL}
  LICENSES "GPL License" ${CPACK_RESOURCE_FILE_LICENSE}
  DEFAULT TRUE)
cpack_ifw_configure_component(
  YuRadioInstaller
  SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/resources/windows/installscript.qs)
