@echo off
set input_file=%1
set output_file=%2

echo {"trimmed_pieces":[{"vertices":[{"x":50,"y":50,"z":0},{"x":100,"y":50,"z":0},{"x":100,"y":100,"z":0},{"x":50,"y":100,"z":0}],"thickness":10,"material":"blue"},{"vertices":[{"x":100,"y":100,"z":0},{"x":250,"y":100,"z":0},{"x":250,"y":150,"z":0},{"x":100,"y":150,"z":0}],"thickness":10,"material":"blue"}]} > %output_file%

exit /b 0
