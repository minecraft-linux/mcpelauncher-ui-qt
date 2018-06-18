cmake_minimum_required(VERSION 3.1)

project(mcpelauncher-ui-qt LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt5 COMPONENTS Core Quick Concurrent REQUIRED)

add_executable(${PROJECT_NAME} main.cpp googleloginhelper.cpp googleloginhelper.h googleaccount.h versionmanager.cpp versionmanager.h apkextractiontask.cpp apkextractiontask.h googleplayapi.cpp googleplayapi.h qml.qrc)

target_link_libraries(${PROJECT_NAME} Qt5::Core Qt5::Quick Qt5::Concurrent playdl-signin-ui-qt-lib mcpelauncher-extract-lib mcpelauncher-elfinfo-lib gplayapi)
