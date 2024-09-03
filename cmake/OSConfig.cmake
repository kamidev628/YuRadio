include_guard(GLOBAL)

# Set minimum CMake version specific to host operating system, add OS-specific
# module directory to default search paths, and set helper variables for OS
# detection in other CMake list files.
if(WIN32)
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/windows")
elseif(APPLE)
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/macos")
elseif(LINUX)
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/linux")
endif()
