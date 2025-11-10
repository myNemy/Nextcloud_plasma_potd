include_directories(${CMAKE_CURRENT_BINARY_DIR}/.. ${CMAKE_CURRENT_SOURCE_DIR}/..)

kcoreaddons_add_plugin(plasma_potd_nextcloudprovider SOURCES nextcloudprovider.cpp INSTALL_NAMESPACE "potd")
target_link_libraries(plasma_potd_nextcloudprovider plasmapotdprovidercore plasma_wallpaper_potdplugin_debug KF6::KIOCore KF6::CoreAddons Qt6::Network)

