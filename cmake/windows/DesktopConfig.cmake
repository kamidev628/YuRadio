include_guard(GLOBAL)

set(yuradio_windows_resource ${CMAKE_BINARY_DIR}/resources/windows/yuradio.rc)
configure_file(resources/windows/yuradio.rc.in ${yuradio_windows_resource})
configure_file(resources/windows/yuradio.ico
               ${CMAKE_BINARY_DIR}/resources/windows/yuradio.ico COPYONLY)
target_sources(YuRadio PRIVATE ${yuradio_windows_resource})
