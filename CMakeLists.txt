cmake_minimum_required(VERSION 3.16)
project(NextcloudPotdProvider VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find ECM (Extra CMake Modules) for KF6
find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_MODULE_PATH})

find_package(Qt6 REQUIRED COMPONENTS Core Network Gui)
find_package(KF6CoreAddons REQUIRED)
find_package(KF6Config REQUIRED)
find_package(KF6KIO REQUIRED)

# Try to find PlasmaPotdProvider library (optional)
# Search in more paths including Qt6 plugin directories
find_library(PLASMA_POTD_PROVIDER_CORE
    NAMES plasmapotdprovidercore
    PATHS
        /usr/lib
        /usr/lib64
        /usr/local/lib
        /usr/local/lib64
        /usr/lib/x86_64-linux-gnu
    PATH_SUFFIXES
        x86_64-linux-gnu
        lib64
        lib
        qt6/plugins
    NO_DEFAULT_PATH
)

# Also try default paths (without NO_DEFAULT_PATH)
if(NOT PLASMA_POTD_PROVIDER_CORE)
    find_library(PLASMA_POTD_PROVIDER_CORE
        NAMES plasmapotdprovidercore
        PATHS
            /usr/lib
            /usr/lib64
            /usr/local/lib
            /usr/local/lib64
    )
endif()

# Try pkg-config as fallback
if(NOT PLASMA_POTD_PROVIDER_CORE)
    find_package(PkgConfig)
    if(PkgConfig_FOUND)
        pkg_check_modules(KF6_POTD QUIET KF6PlasmaPotdProvider)
        if(KF6_POTD_FOUND)
            set(PLASMA_POTD_PROVIDER_CORE ${KF6_POTD_LIBRARIES})
            message(STATUS "Found plasmapotdprovidercore via pkg-config: ${PLASMA_POTD_PROVIDER_CORE}")
        endif()
    endif()
endif

# Find potdprovider.h - try system first, then fallback to included file
find_path(POTD_PROVIDER_INCLUDE_DIR
    NAMES potdprovider.h
    PATHS
        /usr/include
        /usr/local/include
        ${CMAKE_INSTALL_PREFIX}/include
    PATH_SUFFIXES
        plasma/potdprovider
        KF6/plasma/potdprovider
        KF6/Plasma/potdprovider
)

# If not found in system, use the included file
if(NOT POTD_PROVIDER_INCLUDE_DIR)
    message(WARNING "potdprovider.h not found in system, using included file from repository")
    set(POTD_PROVIDER_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/plugins/providers)
endif()

# Warn if library not found but continue anyway
if(NOT PLASMA_POTD_PROVIDER_CORE)
    message(WARNING "plasmapotdprovidercore library not found. Attempting to build without explicit linking.")
    message(WARNING "The library may be linked dynamically by Plasma at runtime.")
else()
    message(STATUS "Found plasmapotdprovidercore: ${PLASMA_POTD_PROVIDER_CORE}")
endif()

message(STATUS "Using potdprovider.h from: ${POTD_PROVIDER_INCLUDE_DIR}")

# Build the provider as a shared library (plugin)
add_library(plasma_potd_nextcloudprovider SHARED
    plugins/providers/nextcloudprovider.cpp
)

set_target_properties(plasma_potd_nextcloudprovider PROPERTIES
    AUTOMOC ON
    PREFIX ""
    OUTPUT_NAME "plasma_potd_nextcloudprovider"
)

target_include_directories(plasma_potd_nextcloudprovider PRIVATE
    ${POTD_PROVIDER_INCLUDE_DIR}
    plugins/providers
)

target_link_libraries(plasma_potd_nextcloudprovider PRIVATE
    Qt6::Core
    Qt6::Network
    Qt6::Gui
    KF6::CoreAddons
    KF6::ConfigCore
    KF6::KIOCore
)

# Link plasmapotdprovidercore only if found
if(PLASMA_POTD_PROVIDER_CORE)
    target_link_libraries(plasma_potd_nextcloudprovider PRIVATE ${PLASMA_POTD_PROVIDER_CORE})
endif()

# Install the plugin to /usr/lib (not /usr/local)
set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "Install path prefix" FORCE)

# Install the plugin
install(TARGETS plasma_potd_nextcloudprovider
    LIBRARY DESTINATION lib/qt6/plugins/potd
)

# Install the JSON file
install(FILES
    plugins/providers/nextcloudprovider.json
    DESTINATION lib/qt6/plugins/potd
)

