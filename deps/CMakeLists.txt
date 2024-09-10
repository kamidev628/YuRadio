if(BUILD_UIOHOOK)
  add_subdirectory(uiohook EXCLUDE_FROM_ALL)
endif()

if(LINUX)
  add_subdirectory(qtmpris)
endif()
