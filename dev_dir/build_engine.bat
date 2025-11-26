@echo off
echo Building PARAMETRIX C++ Geometry Engine...

REM Check if SketchUp SDK exists
if not exist "SketchUpSDK" (
    echo ERROR: SketchUp SDK not found in dev_dir/SketchUpSDK
    echo Please download and extract the SketchUp SDK to dev_dir/SketchUpSDK
    echo Download from: https://developer.sketchup.com/sketchup-sdk
    pause
    exit /b 1
)

REM Create build directory
if not exist "geometry_engine\build" mkdir geometry_engine\build
cd geometry_engine\build

REM Configure with CMake
echo Configuring build with CMake...
cmake .. -G "Visual Studio 16 2019" -A x64

if %ERRORLEVEL% neq 0 (
    echo ERROR: CMake configuration failed
    echo Make sure you have Visual Studio 2019 or later installed
    pause
    exit /b 1
)

REM Build the project
echo Building C++ engine...
cmake --build . --config Release

if %ERRORLEVEL% neq 0 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

REM Copy executable to extension root
if exist "Release\parametrix_engine.exe" (
    copy "Release\parametrix_engine.exe" "..\..\parametrix_engine.exe"
    echo SUCCESS: parametrix_engine.exe built and copied to extension directory
) else (
    echo ERROR: parametrix_engine.exe not found after build
    pause
    exit /b 1
)

cd ..\..
echo Build completed successfully!
echo.
echo Next steps:
echo 1. Test the engine with: parametrix_engine.exe test_input.json test_output.json
echo 2. Update your Ruby extension to use the new trimming_v4_cpp.rb
echo 3. Test with your problematic L-shaped wall
echo.
pause