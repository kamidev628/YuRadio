# NOTE: File were taken from obs-studio repo

include_guard(GLOBAL)

set(_yuradio_version "1" "0" "0")
set(_yuradio_version_canonical ${_yuradio_version})

# Attempt to automatically discover expected YURADIO version
if(NOT DEFINED YURADIO_VERSION_OVERRIDE AND EXISTS
                                            "${CMAKE_CURRENT_SOURCE_DIR}/.git")
  execute_process(
    COMMAND git describe --always --tags --dirty=-modified
    OUTPUT_VARIABLE _yuradio_version
    ERROR_VARIABLE _git_describe_err
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    RESULT_VARIABLE _yuradio_version_result
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  if(_git_describe_err)
    message(FATAL_ERROR "Could not fetch YURADIO version tag from git.\n"
                        ${_git_describe_err})
  endif()

  if(_yuradio_version_result EQUAL 0)
    string(REGEX REPLACE "([0-9]+)\\.([0-9]+)\\.([0-9]+).*" "\\1;\\2;\\3"
                         _yuradio_version_canonical ${_yuradio_version})
  endif()
elseif(DEFINED YURADIO_VERSION_OVERRIDE)
  if(YURADIO_VERSION_OVERRIDE MATCHES "([0-9]+)\\.([0-9]+)\\.([0-9]+).*")
    string(REGEX REPLACE "([0-9]+)\\.([0-9]+)\\.([0-9]+).*" "\\1;\\2;\\3"
                         _yuradio_version_canonical ${YURADIO_VERSION_OVERRIDE})
    set(_yuradio_version ${YURADIO_VERSION_OVERRIDE})
  else()
    message(
      FATAL_ERROR
        "Invalid version supplied - must be <MAJOR>.<MINOR>.<PATCH>[-(rc|beta)<NUMBER>]."
    )
  endif()
endif()

# Set beta/rc versions if suffix included in version string
if(_yuradio_version MATCHES "[0-9]+\\.[0-9]+\\.[0-9]+-rc[0-9]+")
  string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.[0-9]+-rc([0-9]+).*$" "\\1"
                       _yuradio_release_candidate ${_yuradio_version})
elseif(_yuradio_version MATCHES "[0-9]+\\.[0-9]+\\.[0-9]+-beta[0-9]+")
  string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.[0-9]+-beta([0-9]+).*$" "\\1"
                       _yuradio_beta ${_yuradio_version})
endif()

list(GET _yuradio_version_canonical 0 YURADIO_VERSION_MAJOR)
list(GET _yuradio_version_canonical 1 YURADIO_VERSION_MINOR)
list(GET _yuradio_version_canonical 2 YURADIO_VERSION_PATCH)

set(YURADIO_RELEASE_CANDIDATE ${_yuradio_release_candidate})
set(YURADIO_BETA ${_yuradio_beta})

string(REPLACE ";" "." YURADIO_VERSION_CANONICAL
               "${_yuradio_version_canonical}")
string(REPLACE ";" "." YURADIO_VERSION "${_yuradio_version}")

if(YURADIO_RELEASE_CANDIDATE GREATER 0)
  message(
    AUTHOR_WARNING
      "******************************************************************************\n"
      "  + YURADIO-Studio - Release candidate detected, YURADIO_VERSION is now: ${YURADIO_VERSION}\n"
      "******************************************************************************"
  )
elseif(YURADIO_BETA GREATER 0)
  message(
    AUTHOR_WARNING
      "******************************************************************************\n"
      "  + YURADIO-Studio - Beta detected, YURADIO_VERSION is now: ${YURADIO_VERSION}\n"
      "******************************************************************************"
  )
endif()

unset(_yuradio_version)
unset(_yuradio_version_canonical)
unset(_yuradio_release_candidate)
unset(_yuradio_beta)
unset(_yuradio_version_result)
