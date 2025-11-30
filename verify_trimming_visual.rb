# Visual Trimming Verification Tool
# Colors faces based on whether they're inside/outside boundary

load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/lib/PARAMETRIX/trimming_v4_enhanced.rb'

def verify_trimming_visual
  model = Sketchup.active_model
  selection = model.selection
  
  # Need 2 selections: boundary face + layout group
  faces = selection.grep(Sketchup::Face)
  groups = selection.grep(Sketchup::Group)
  
  if faces.empty? || groups.empty?
    puts "ERROR: Select 1 face (boundary) + 1 group (layout)"
    return
  end
  
  boundary_face = faces.first
  layout_group = groups.first
  
  model.start_operation("Visual Verification", true)
  
  # Create materials
  mat_inside = model.materials.add("Inside_Green")
  mat_inside.color = Sketchup::Color.new(0, 255, 0, 128)
  
  mat_outside = model.materials.add("Outside_Red")
  mat_outside.color = Sketchup::Color.new(255, 0, 0, 128)
  
  mat_partial = model.materials.add("Partial_Yellow")
  mat_partial.color = Sketchup::Color.new(255, 255, 0, 128)
  
  inside_count = 0
  outside_count = 0
  partial_count = 0
  
  # Classify each face
  layout_group.entities.grep(Sketchup::Face).each do |face|
    # Sample multiple points
    sample_points = []
    sample_points << face.bounds.center
    face.outer_loop.vertices.each { |v| sample_points << v.position }
    face.outer_loop.edges.each do |edge|
      mid = Geom::Point3d.new(
        (edge.start.position.x + edge.end.position.x) / 2.0,
        (edge.start.position.y + edge.end.position.y) / 2.0,
        (edge.start.position.z + edge.end.position.z) / 2.0
      )
      sample_points << mid
    end
    
    outside = 0
    inside = 0
    
    sample_points.each do |pt|
      if boundary_face.classify_point(pt) == Sketchup::Face::PointOutside
        outside += 1
      else
        inside += 1
      end
    end
    
    # Color based on classification
    if outside == 0
      face.material = mat_inside
      inside_count += 1
    elsif inside == 0
      face.material = mat_outside
      outside_count += 1
    else
      face.material = mat_partial
      partial_count += 1
    end
  end
  
  model.commit_operation
  
  puts "\n" + "="*60
  puts "Visual Verification Results"
  puts "="*60
  puts "GREEN (Inside): #{inside_count} faces"
  puts "RED (Outside): #{outside_count} faces - SHOULD BE REMOVED"
  puts "YELLOW (Partial): #{partial_count} faces - EDGE CASES"
  puts "\nRED faces will be removed by trimming algorithm"
  puts "="*60
end

puts "\n\nVISUAL VERIFICATION TOOL"
puts "="*60
puts "1. Create a layout group (or use existing)"
puts "2. Select: boundary face + layout group"
puts "3. Run: verify_trimming_visual"
puts "\nColors:"
puts "  GREEN = Inside boundary (kept)"
puts "  RED = Outside boundary (removed)"
puts "  YELLOW = Partially inside (edge case)"
puts "="*60
