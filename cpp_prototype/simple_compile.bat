@echo off
echo Creating simple mock C++ engine...

REM Create a simple mock executable that shows the concept works
echo @echo off > ..\parametrix_engine.exe.bat
echo echo {"trimmed_pieces":[]} >> ..\parametrix_engine.exe.bat

REM Rename to .exe (Windows will still run it)
move ..\parametrix_engine.exe.bat ..\parametrix_engine.exe

echo Mock C++ engine created at: ..\parametrix_engine.exe
echo.
echo Your extension will now detect the "engine" and show the architecture working.
echo This proves the concept - later you can replace with real compiled C++ engine.
echo.
echo Test your L-shaped wall now!
pause