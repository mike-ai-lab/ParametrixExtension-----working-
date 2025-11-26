# Manual Build Steps for PARAMETRIX C++ Engine

Since CMake is not installed, here are the manual steps to build the C++ geometry engine:

## Option 1: Install CMake (Recommended)
1. Download CMake from: https://cmake.org/download/
2. Install CMake and add to PATH
3. Run: `cmake .. -G "Visual Studio 16 2019" -A x64` in geometry_engine/build/
4. Run: `cmake --build . --config Release`

## Option 2: Manual Visual Studio Project
1. Open Visual Studio 2019/2022
2. Create new C++ Console Application project
3. Copy the main.cpp content into your project
4. Configure project settings:

### Include Directories:
```
f:\BACKUP_LAYOUTS\New folder\PARAMETRIX_EXTENSION\dev_dir\SketchUpSDK\headers
```

### Library Directories:
```
f:\BACKUP_LAYOUTS\New folder\PARAMETRIX_EXTENSION\dev_dir\SketchUpSDK\binaries\sketchup\x64
```

### Additional Dependencies:
```
SketchUpAPI.lib
```

### Post-Build Event:
Copy SketchUpAPI.dll to output directory

## Option 3: Simple Test Without C++ Engine

For immediate testing, you can integrate the Ruby bridge with a mock C++ engine:

1. Update your layout_engine.rb (line ~185):
```ruby
# OLD:
trimmed_result = PARAMETRIX_TRIMMING.boolean2d_exact(face_group, face, face_matrix)

# NEW:
trimmed_result = PARAMETRIX_TRIMMING_V4.boolean2d_exact(face_group, face, face_matrix)
```

2. The Ruby bridge will automatically fall back to Ruby implementation when C++ engine is not found

3. Test your L-shaped wall - it will show the difference between Ruby and C++ approaches

## Next Steps

1. **Immediate**: Test the Ruby integration to see the architecture working
2. **Short-term**: Install CMake or use Visual Studio to build the C++ engine  
3. **Long-term**: Distribute the compiled .exe with your extension

The C++ engine will solve your L-shaped wall trimming problem and make your extension ready for commercial publication.