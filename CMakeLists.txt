cmake_minimum_required(VERSION 3.1)

project(mcpelauncher-ui-qt LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt5 COMPONENTS Core Quick Concurrent Svg REQUIRED)

option(ENABLE_UPDATE_CHECK "Enables update checking with a remote server")
set(UPDATE_CHECK_URL "" CACHE STRING "Specify the URL for the server to check for updates on")
set(UPDATE_CHECK_BUILD_ID "" CACHE STRING "Specify the numeral version number for the current build")

add_executable(${PROJECT_NAME} main.cpp launcherapp.cpp launcherapp.h googleloginhelper.cpp googleloginhelper.h googleaccount.h versionmanager.cpp versionmanager.h apkextractiontask.cpp apkextractiontask.h googleplayapi.cpp googleplayapi.h googleversionchannel.cpp googleversionchannel.h googleapkdownloadtask.cpp googleapkdownloadtask.h gamelauncher.cpp gamelauncher.h profilemanager.cpp profilemanager.h qmlurlutils.h archivalversionlist.cpp archivalversionlist.h launchersettings.h troubleshooter.cpp troubleshooter.h updatechecker.cpp updatechecker.h qml.qrc)
if (ENABLE_UPDATE_CHECK)
    target_compile_definitions(${PROJECT_NAME} PUBLIC UPDATE_CHECK UPDATE_CHECK_BUILD_ID=${UPDATE_CHECK_BUILD_ID} UPDATE_CHECK_URL="${UPDATE_CHECK_URL}")
endif()
if (APPLE)
    target_sources(${PROJECT_NAME} PUBLIC launcherapp_osx.mm)
    target_link_libraries(${PROJECT_NAME} "-framework AppKit")
    if(ENABLE_SPARKLE_UPDATE_CHECK)
        target_sources(${PROJECT_NAME} PUBLIC sparkle_updatechecker.mm)
        target_compile_definitions(${PROJECT_NAME} PUBLIC SPARKLE_UPDATE_CHECK=1)
        target_link_libraries(${PROJECT_NAME} "-framework Sparkle")
    endif()
endif()

target_link_libraries(${PROJECT_NAME} Qt5::Core Qt5::Quick Qt5::Svg Qt5::Concurrent playdl-signin-ui-qt-lib mcpelauncher-extract-lib mcpelauncher-apkinfo file-util gplayapi)

if (ENABLE_APPIMAGE_UPDATE_CHECK)
    target_compile_definitions(${PROJECT_NAME} PUBLIC APPIMAGE_UPDATE_CHECK=1)
    target_link_libraries(${PROJECT_NAME} z libappimageupdate)
endif()

install(TARGETS mcpelauncher-ui-qt RUNTIME COMPONENT mcpelauncher-ui-qt DESTINATION bin)
if (NOT APPLE)
    install(FILES mcpelauncher-ui-qt.desktop COMPONENT mcpelauncher-ui-qt DESTINATION share/applications)
    install(FILES Resources/proprietary/mcpelauncher-icon-512.png RENAME mcpelauncher-ui-qt.png
            COMPONENT mcpelauncher-ui-qt DESTINATION share/pixmaps)
endif()
include(CPackSettings.cmake)
