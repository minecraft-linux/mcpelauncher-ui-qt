cmake_minimum_required(VERSION 3.1)

project(mcpelauncher-ui-qt LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt5 COMPONENTS Core Quick Concurrent Svg REQUIRED)

add_executable(${PROJECT_NAME} main.cpp googleloginhelper.cpp googleloginhelper.h googleaccount.h versionmanager.cpp versionmanager.h apkextractiontask.cpp apkextractiontask.h googleplayapi.cpp googleplayapi.h googleversionchannel.cpp googleversionchannel.h googleapkdownloadtask.cpp googleapkdownloadtask.h gamelauncher.cpp gamelauncher.h profilemanager.cpp profilemanager.h qmlurlutils.h archivalversionlist.cpp archivalversionlist.h launchersettings.h qml.qrc)

target_link_libraries(${PROJECT_NAME} Qt5::Core Qt5::Quick Qt5::Svg Qt5::Concurrent playdl-signin-ui-qt-lib mcpelauncher-extract-lib mcpelauncher-apkinfo file-util gplayapi)

install(TARGETS mcpelauncher-ui-qt RUNTIME DESTINATION bin)
