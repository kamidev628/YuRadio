configure_file(resources/linux/com.yuradioproject.metainfo.xml.in
               com.yuradioproject.metainfo.xml)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/com.yuradioproject.metainfo.xml"
        DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/metainfo")

install(FILES resources/linux/com.yuradioproject.desktop
        DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/applications")

install(
  FILES resources/linux/icons/yuradio-logo-128.png
  DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/128x128/apps"
  RENAME com.yuradioproject.png)

install(
  FILES resources/linux/icons/yuradio-logo-256.png
  DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/256x256/apps"
  RENAME com.yuradioproject.png)

install(
  FILES resources/linux/icons/yuradio-logo-512.png
  DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/512x512/apps"
  RENAME com.yuradioproject.png)

install(
  FILES resources/linux/icons/yuradio-logo-scalable.svg
  DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps"
  RENAME com.yuradioproject.svg)
