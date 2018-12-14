cmake_minimum_required(VERSION 3.1)

project(mcpelauncher-ui-qt LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt5 COMPONENTS Core Quick Concurrent Svg REQUIRED)

add_executable(${PROJECT_NAME} main.cpp launcherapp.cpp launcherapp.h googleloginhelper.cpp googleloginhelper.h googleaccount.h versionmanager.cpp versionmanager.h apkextractiontask.cpp apkextractiontask.h googleplayapi.cpp googleplayapi.h googleversionchannel.cpp googleversionchannel.h googleapkdownloadtask.cpp googleapkdownloadtask.h gamelauncher.cpp gamelauncher.h profilemanager.cpp profilemanager.h qmlurlutils.h archivalversionlist.cpp archivalversionlist.h launchersettings.h troubleshooter.cpp troubleshooter.h qml.qrc)
if (APPLE)
    target_sources(${PROJECT_NAME} PUBLIC launcherapp_osx.mm)
    target_link_libraries(${PROJECT_NAME} "-framework AppKit")
endif()

target_link_libraries(${PROJECT_NAME} Qt5::Core Qt5::Quick Qt5::Svg Qt5::Concurrent playdl-signin-ui-qt-lib mcpelauncher-extract-lib mcpelauncher-apkinfo file-util gplayapi)

install(TARGETS mcpelauncher-ui-qt RUNTIME COMPONENT mcpelauncher-ui-qt DESTINATION bin)
install(FILES mcpelauncher-ui-qt.desktop COMPONENT mcpelauncher-ui-qt DESTINATION share/applications)
install(FILES Resources/proprietary/mcpelauncher-icon-512.png RENAME mcpelauncher-ui-qt.png COMPONENT mcpelauncher-ui-qt
        DESTINATION share/pixmaps)
include(CPackSettings.cmake)
