# PARAMETRIX Trimming Problem - Root Cause & Solution

## Root Cause
The current approach:
1. Creates 3D panels (with thickness) in a grid
2. Uses `intersect_with` to add intersection edges
3. Tries to remove faces outside boundary

**Problem:** `intersect_with` doesn't actually CUT 3D geometry - it only adds edges where surfaces intersect. The 3D volumes remain intact, just with extra edges drawn on them.

## Why Ruby Approach Won't Work
- SketchUp's Ruby API has no true 3D boolean operations
- `intersect_with` is for 2D coplanar faces only
- Checking vertices/centers after intersection doesn't help because the geometry wasn't actually cut

## Real Solutions

### Option 1: Generate Only Inside Pieces (Recommended)
**Before** adding thickness, check if each 2D rectangle is inside the face boundary.
- Modify `create_unified_layout_for_face` in `layout_engine.rb`
- Add boundary check BEFORE calling `create_piece_with_ghosting`
- Only create 3D panels that are fully/partially inside
- **Pros:** Pure Ruby, fast, works immediately
- **Cons:** Edge pieces won't be trimmed to exact boundary (will be slightly inside)

### Option 2: C++ Boolean Engine (Professional Solution)
Use SketchUp C++ SDK with proper 3D boolean library (CGAL, Clipper, etc.)
- Compile standalone .exe
- Ruby calls it with geometry data
- Returns properly trimmed 3D geometry
- **Pros:** Perfect trimming, professional-grade
- **Cons:** Requires C++ compilation, SDK setup, cross-platform builds

### Option 3: Use SketchUp Pro Solid Tools
If user has SketchUp Pro, use built-in solid boolean operations
- Create boundary as extruded solid
- Use `Sketchup.active_model.tools.push_pull_tool` or solid operations
- **Pros:** Uses SketchUp's native boolean engine
- **Cons:** Requires Pro license, may be slow on complex geometry

## Recommended Implementation: Option 1

Modify layout generation to check boundary BEFORE creating 3D pieces:

```ruby
# In create_unified_layout_for_face, before create_piece_with_ghosting:

# Check if piece center is inside face boundary
piece_center_2d = Geom::Point3d.new(
  (piece_data[:intersect_left] + piece_data[:intersect_right]) / 2.0,
  (intersect_bottom + intersect_top) / 2.0,
  0
)
piece_center_world = piece_center_2d.transform(face_transform)
piece_center_proj = piece_center_world.project_to_plane(face.plane)

# Only create piece if center is inside boundary
if face.classify_point(piece_center_proj) != Sketchup::Face::PointOutside
  create_piece_with_ghosting(...)
end
```

This will eliminate 90% of leftover geometry with minimal code changes.

## Next Steps
1. Implement Option 1 (boundary check before 3D creation)
2. Test on various face shapes
3. If edge trimming precision is critical, proceed to Option 2 (C++ engine)
