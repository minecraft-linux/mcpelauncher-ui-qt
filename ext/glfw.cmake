include(FetchContent)

set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GLFW_INSTALL OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_WAYLAND OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
        glfw3_ext
        URL "https://github.com/minecraft-linux/glfw/archive/3ec31853c4b3c2eb1c066dab56bf8443ae82f8dd.zip"
)


if(POLICY CMP0169)
  FetchContent_MakeAvailable(glfw3_ext)
else()
  if(NOT glfw3_ext_POPULATED)
    FetchContent_Populate(glfw3_ext)
    add_subdirectory(${glfw3_ext_SOURCE_DIR} ${glfw3_ext_BINARY_DIR})
  endif()
endif()
add_library(glfw3 ALIAS glfw)
