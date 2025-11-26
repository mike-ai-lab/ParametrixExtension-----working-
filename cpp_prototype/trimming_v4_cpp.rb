# PARAMETRIX Trimming V4 - C++ Engine Integration
# Replaces unreliable Ruby boolean operations with precise C++ geometry processing

require_relative 'geometry_bridge'

module PARAMETRIX_TRIMMING_V4

  PARAMETRIX_TRIM_VERSION = "PARAMETRIX_TRIM_V4_CPP_1.0" unless defined?(PARAMETRIX_TRIM_VERSION)

  def self.boolean2d_exact(layout_group, original_face, face_matrix = nil)
    begin
      puts "[TRIM_V4] Starting C++ enhanced boolean trimming..."
      
      unless layout_group && original_face
        puts "[TRIM_V4] Missing required parameters"
        return layout_group
      end

      # Prepare face data for C++ engine
      face_data = {
        face: original_face,
        matrix: face_matrix || Geom::Transformation.new
      }
      
      # Extract layout pieces from the group
      layout_pieces = extract_layout_pieces_from_group(layout_group)
      
      if layout_pieces.empty?
        puts "[TRIM_V4] No layout pieces found to trim"
        return layout_group
      end
      
      puts "[TRIM_V4] Processing #{layout_pieces.length} layout pieces with C++ engine"
      
      # Process with C++ geometry engine (with Ruby fallback)
      trimmed_pieces = PARAMETRIX_GEOMETRY_BRIDGE.process_layout_with_fallback(face_data, layout_pieces)
      
      if trimmed_pieces.nil? || trimmed_pieces.empty?
        puts "[TRIM_V4] C++ processing failed, returning original layout"
        return layout_group
      end
      
      # Create new group with trimmed geometry
      model = Sketchup.active_model
      entities = model.active_entities
      
      # Remove original layout group
      layout_group.erase! if layout_group.valid?
      
      # Create new trimmed group
      trimmed_group = entities.add_group
      trimmed_group.name = "PARAMETRIX Layout (C++ Trimmed)"
      
      # Add trimmed pieces to new group
      trimmed_pieces.each_with_index do |piece, index|
        create_trimmed_piece(trimmed_group, piece, index)
      end
      
      # Convert to cutting component
      inst = trimmed_group.to_component
      defn = inst.definition
      be = defn.behavior
      be.is2d = true
      be.cuts_opening = true
      be.snapto = 0
      defn.invalidate_bounds
      
      inst.name = "PARAMETRIX Layout"
      defn.name = "PARAMETRIX Layout Def"
      
      puts "[TRIM_V4] C++ trimming completed successfully"
      return inst
      
    rescue => e
      puts "[TRIM_V4] Error in C++ trimming: #{e.message}"
      puts "[TRIM_V4] Backtrace: #{e.backtrace.first(5).join('\n')}"
      return layout_group
    end
  end
  
  private
  
  def self.extract_layout_pieces_from_group(layout_group)
    pieces = []
    
    layout_group.entities.each do |entity|
      if entity.is_a?(Sketchup::Face)
        # Extract face geometry
        vertices = entity.outer_loop.vertices.map { |v| v.position }
        
        # Get material and thickness info
        material_name = entity.material ? entity.material.name : "default"
        
        # Estimate thickness from face normal and any connected geometry
        thickness = estimate_face_thickness(entity)
        
        pieces << {
          vertices: vertices,
          thickness: thickness,
          material: material_name,
          original_face: entity
        }
        
      elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        # Recursively extract from nested groups/components
        nested_pieces = extract_layout_pieces_from_nested_entity(entity)
        pieces.concat(nested_pieces)
      end
    end
    
    puts "[TRIM_V4] Extracted #{pieces.length} layout pieces"
    return pieces
  end
  
  def self.extract_layout_pieces_from_nested_entity(entity)
    pieces = []
    
    # Get the entities collection
    if entity.is_a?(Sketchup::Group)
      nested_entities = entity.entities
      transform = entity.transformation
    elsif entity.is_a?(Sketchup::ComponentInstance)
      nested_entities = entity.definition.entities
      transform = entity.transformation
    else
      return pieces
    end
    
    # Extract faces from nested entity
    nested_entities.each do |nested_entity|
      if nested_entity.is_a?(Sketchup::Face)
        # Transform vertices to world coordinates
        vertices = nested_entity.outer_loop.vertices.map do |v|
          v.position.transform(transform)
        end
        
        material_name = nested_entity.material ? nested_entity.material.name : "default"
        thickness = estimate_face_thickness(nested_entity)
        
        pieces << {
          vertices: vertices,
          thickness: thickness,
          material: material_name,
          original_face: nested_entity
        }
      end
    end
    
    return pieces
  end
  
  def self.estimate_face_thickness(face)
    # Try to determine thickness from connected geometry or use default
    # This is a simplified estimation - in practice you might have thickness stored elsewhere
    
    # Check if face has a material with thickness info in the name
    if face.material && face.material.name.match(/(\d+(?:\.\d+)?)(?:mm|cm|m|in)/)
      thickness_str = $1
      return thickness_str.to_f
    end
    
    # Default thickness based on face size (rough estimation)
    area = face.area
    if area < 1000 # Small pieces, thin material
      return 0.05 # 5cm default
    elsif area < 10000 # Medium pieces
      return 0.1 # 10cm default
    else # Large pieces
      return 0.15 # 15cm default
    end
  end
  
  def self.create_trimmed_piece(group, piece_data, index)
    begin
      vertices = piece_data[:vertices]
      return unless vertices && vertices.length >= 3
      
      # Create face from trimmed vertices
      face = group.entities.add_face(vertices)
      return unless face && face.valid?
      
      # Apply material if specified
      if piece_data[:material] && piece_data[:material] != "default"
        material = Sketchup.active_model.materials[piece_data[:material]]
        face.material = material if material
      end
      
      # Add thickness if specified (pushpull)
      if piece_data[:thickness] && piece_data[:thickness] > 0.001
        face.pushpull(piece_data[:thickness])
      end
      
      puts "[TRIM_V4] Created trimmed piece #{index + 1} with #{vertices.length} vertices"
      
    rescue => e
      puts "[TRIM_V4] Error creating trimmed piece #{index}: #{e.message}"
    end
  end
  
  # Diagnostic method to check C++ engine status
  def self.engine_status
    if PARAMETRIX_GEOMETRY_BRIDGE.engine_available?
      puts "[TRIM_V4] ✅ C++ geometry engine available - precise boolean operations enabled"
      return true
    else
      puts "[TRIM_V4] ⚠️  C++ geometry engine not found - using Ruby fallback"
      puts "[TRIM_V4] Expected engine at: #{PARAMETRIX_GEOMETRY_BRIDGE::ENGINE_PATH}"
      return false
    end
  end

end