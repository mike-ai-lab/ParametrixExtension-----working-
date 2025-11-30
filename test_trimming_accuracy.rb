# PARAMETRIX Trimming Accuracy Test Suite
# Tests trimming on various face shapes and measures leftover geometry

require 'sketchup.rb'

module PARAMETRIX_TEST

  def self.run_trimming_tests
    model = Sketchup.active_model
    model.start_operation("Trimming Test", true)
    
    puts "\n" + "="*80
    puts "[TEST] PARAMETRIX Trimming Accuracy Test Suite"
    puts "="*80
    
    test_results = []
    
    # Test 1: Rectangle
    test_results << test_shape("Rectangle", create_rectangle_face)
    
    # Test 2: Triangle
    test_results << test_shape("Triangle", create_triangle_face)
    
    # Test 3: Pentagon
    test_results << test_shape("Pentagon", create_pentagon_face)
    
    # Test 4: Irregular Polygon
    test_results << test_shape("Irregular", create_irregular_face)
    
    # Test 5: Face with hole
    test_results << test_shape("With Hole", create_face_with_hole)
    
    model.abort_operation
    
    # Summary
    puts "\n" + "="*80
    puts "[TEST] Summary"
    puts "="*80
    test_results.each do |result|
      status = result[:leftover_volume] < 0.01 ? "✓ PASS" : "✗ FAIL"
      puts "#{status} | #{result[:name]}: #{result[:leftover_volume].round(4)} leftover volume"
    end
    
    passed = test_results.count { |r| r[:leftover_volume] < 0.01 }
    puts "\nPassed: #{passed}/#{test_results.length}"
    puts "="*80
  end

  def self.test_shape(name, face_data)
    puts "\n[TEST] Testing #{name}..."
    
    face = face_data[:face]
    group = face_data[:group]
    
    # Create simple layout (3x3 grid covering face)
    layout_group = create_test_layout(face)
    
    # Apply trimming
    trimmed = PARAMETRIX_TRIMMING_V4.boolean2d_exact(layout_group, face, nil)
    
    # Measure leftover geometry
    leftover = measure_leftover_geometry(trimmed, face)
    
    # Cleanup
    trimmed.erase! if trimmed && trimmed.respond_to?(:erase!)
    group.erase! if group && group.respond_to?(:erase!)
    
    puts "[TEST] #{name}: Leftover volume = #{leftover.round(4)}"
    
    { name: name, leftover_volume: leftover }
  end

  def self.create_test_layout(face)
    model = Sketchup.active_model
    ents = model.active_entities
    
    bounds = face.bounds
    layout_group = ents.add_group
    layout_ents = layout_group.entities
    
    # Create 3x3 grid of rectangles covering the face
    width = bounds.width / 3.0
    height = bounds.height / 3.0
    thickness = 10.mm
    
    3.times do |row|
      3.times do |col|
        x = bounds.min.x + col * width
        y = bounds.min.y + row * height
        
        pts = [
          Geom::Point3d.new(x, y, 0),
          Geom::Point3d.new(x + width, y, 0),
          Geom::Point3d.new(x + width, y + height, 0),
          Geom::Point3d.new(x, y + height, 0)
        ]
        
        f = layout_ents.add_face(pts)
        f.pushpull(-thickness) if f
      end
    end
    
    layout_group
  end

  def self.measure_leftover_geometry(trimmed_group, boundary_face)
    return 0.0 unless trimmed_group && trimmed_group.respond_to?(:entities)
    
    total_outside_volume = 0.0
    
    trimmed_group.entities.grep(Sketchup::Face).each do |face|
      center = face.bounds.center
      if boundary_face.classify_point(center) == Sketchup::Face::PointOutside
        total_outside_volume += face.area * 10.mm # Approximate volume
      end
    end
    
    total_outside_volume
  end

  # Test face generators
  def self.create_rectangle_face
    model = Sketchup.active_model
    ents = model.active_entities
    group = ents.add_group
    
    pts = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(1000.mm, 0, 0),
      Geom::Point3d.new(1000.mm, 1000.mm, 0),
      Geom::Point3d.new(0, 1000.mm, 0)
    ]
    
    face = group.entities.add_face(pts)
    { face: face, group: group }
  end

  def self.create_triangle_face
    model = Sketchup.active_model
    ents = model.active_entities
    group = ents.add_group
    
    pts = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(1000.mm, 0, 0),
      Geom::Point3d.new(500.mm, 1000.mm, 0)
    ]
    
    face = group.entities.add_face(pts)
    { face: face, group: group }
  end

  def self.create_pentagon_face
    model = Sketchup.active_model
    ents = model.active_entities
    group = ents.add_group
    
    center = Geom::Point3d.new(500.mm, 500.mm, 0)
    radius = 500.mm
    pts = []
    
    5.times do |i|
      angle = (i * 72.0 - 90.0) * Math::PI / 180.0
      pts << Geom::Point3d.new(
        center.x + radius * Math.cos(angle),
        center.y + radius * Math.sin(angle),
        0
      )
    end
    
    face = group.entities.add_face(pts)
    { face: face, group: group }
  end

  def self.create_irregular_face
    model = Sketchup.active_model
    ents = model.active_entities
    group = ents.add_group
    
    pts = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(1000.mm, 0, 0),
      Geom::Point3d.new(1200.mm, 600.mm, 0),
      Geom::Point3d.new(800.mm, 1000.mm, 0),
      Geom::Point3d.new(200.mm, 800.mm, 0)
    ]
    
    face = group.entities.add_face(pts)
    { face: face, group: group }
  end

  def self.create_face_with_hole
    model = Sketchup.active_model
    ents = model.active_entities
    group = ents.add_group
    
    # Outer boundary
    outer = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(1000.mm, 0, 0),
      Geom::Point3d.new(1000.mm, 1000.mm, 0),
      Geom::Point3d.new(0, 1000.mm, 0)
    ]
    
    face = group.entities.add_face(outer)
    
    # Inner hole
    inner = [
      Geom::Point3d.new(300.mm, 300.mm, 0),
      Geom::Point3d.new(700.mm, 300.mm, 0),
      Geom::Point3d.new(700.mm, 700.mm, 0),
      Geom::Point3d.new(300.mm, 700.mm, 0)
    ]
    
    hole_face = group.entities.add_face(inner)
    hole_face.erase! if hole_face
    
    face = group.entities.grep(Sketchup::Face).first
    { face: face, group: group }
  end

end

# Run tests from Ruby Console:
# PARAMETRIX_TEST.run_trimming_tests
