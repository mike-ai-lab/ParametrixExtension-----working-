cmake_minimum_required(VERSION 3.10)
project(ParametrixGeometryEngine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find SketchUp SDK
set(SKETCHUP_SDK_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../SketchUpSDK")

# Include directories
include_directories(${SKETCHUP_SDK_PATH}/headers)

# Link directories
if(WIN32)
    link_directories(${SKETCHUP_SDK_PATH}/binaries/sketchup/x64)
    set(SKETCHUP_LIBS SketchUpAPI)
elseif(APPLE)
    link_directories(${SKETCHUP_SDK_PATH}/binaries/sketchup/x64)
    set(SKETCHUP_LIBS SketchUpAPI)
else()
    # Linux
    link_directories(${SKETCHUP_SDK_PATH}/binaries/sketchup/x64)
    set(SKETCHUP_LIBS SketchUpAPI)
endif()

# Add executable
add_executable(parametrix_engine main.cpp)

# Link libraries
target_link_libraries(parametrix_engine ${SKETCHUP_LIBS})

# Set output directory
set_target_properties(parametrix_engine PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../../"
)

# Copy SketchUp DLLs to output directory (Windows)
if(WIN32)
    add_custom_command(TARGET parametrix_engine POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${SKETCHUP_SDK_PATH}/binaries/sketchup/x64/SketchUpAPI.dll"
        "${CMAKE_CURRENT_SOURCE_DIR}/../../"
    )
endif()