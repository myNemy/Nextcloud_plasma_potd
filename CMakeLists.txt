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

# Try to find PlasmaPotdProvider
# If not found, we'll need to build it or use installed version
find_library(PLASMA_POTD_PROVIDER_CORE
    NAMES plasmapotdprovidercore
    PATHS
        /usr/lib
        /usr/lib64
        /usr/local/lib
        /usr/local/lib64
    PATH_SUFFIXES
        x86_64-linux-gnu
        lib64
        lib
)

if(NOT PLASMA_POTD_PROVIDER_CORE)
    message(WARNING "plasmapotdprovidercore not found. You may need to install kdeplasma-addons or build it separately.")
    message(STATUS "Trying to find via pkg-config...")
    
    # Try pkg-config
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(KF6_POTD QUIET KF6PlasmaPotdProvider)
    
    if(KF6_POTD_FOUND)
        set(PLASMA_POTD_PROVIDER_CORE ${KF6_POTD_LIBRARIES})
        message(STATUS "Found via pkg-config: ${PLASMA_POTD_PROVIDER_CORE}")
    else()
        message(FATAL_ERROR "plasmapotdprovidercore library not found. Please install kdeplasma-addons development packages.")
    endif()
endif()

# Find potdprovider.h
find_path(POTD_PROVIDER_INCLUDE_DIR
    NAMES potdprovider.h
    PATHS
        /usr/include
        /usr/local/include
        ${CMAKE_INSTALL_PREFIX}/include
    PATH_SUFFIXES
        plasma/potdprovider
        KF6/plasma/potdprovider
)

if(NOT POTD_PROVIDER_INCLUDE_DIR)
    message(FATAL_ERROR "potdprovider.h not found. Please install kdeplasma-addons development packages.")
endif()

message(STATUS "Found potdprovider.h in: ${POTD_PROVIDER_INCLUDE_DIR}")
message(STATUS "Found plasmapotdprovidercore: ${PLASMA_POTD_PROVIDER_CORE}")

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
    ${PLASMA_POTD_PROVIDER_CORE}
    Qt6::Core
    Qt6::Network
    Qt6::Gui
    KF6::CoreAddons
    KF6::ConfigCore
    KF6::KIOCore
)

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

# Build GUI configuration tool (standalone, no provider compilation needed)
option(BUILD_GUI "Build GUI configuration tool" ON)
if(BUILD_GUI)
    add_subdirectory(gui)
endif()

