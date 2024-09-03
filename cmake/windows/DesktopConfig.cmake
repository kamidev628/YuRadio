include_guard(GLOBAL)

set(app_icon_resource_windows "resources/windows/yuradio.rc")
configure_file("resources/windows/yuradio.rc.in" ${app_icon_resource_windows})
target_sources(YuRadio PRIVATE ${app_icon_resource_windows})
