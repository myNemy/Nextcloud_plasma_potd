cmake_minimum_required(VERSION 3.16)

# Standalone GUI - no dependency on provider compilation
find_package(Qt6 REQUIRED COMPONENTS Core Quick Qml)

find_package(KF6 REQUIRED COMPONENTS ConfigCore)

qt6_add_executable(nextcloud-wallpaper-config
    main.cpp
)

qt6_add_qml_module(nextcloud-wallpaper-config
    URI NextcloudWallpaperConfig
    VERSION 1.0
    QML_FILES
        main.qml
)

target_link_libraries(nextcloud-wallpaper-config PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Qml
    KF6::ConfigCore
)

set_target_properties(nextcloud-wallpaper-config PROPERTIES
    AUTOMOC ON
)

# Install the application
install(TARGETS nextcloud-wallpaper-config
    RUNTIME DESTINATION bin
)

