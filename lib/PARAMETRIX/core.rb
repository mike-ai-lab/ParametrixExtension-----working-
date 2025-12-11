# PARAMETRIX Core Module (Replaced with stable V121 logic)
# Contains module definitions, constants, and global configuration

module PARAMETRIX
  
  PARAMETRIX_EXTENSION_VERSION = "1.0_OOB_TRIM_V7"
  
  # --- Multi-Row Layout Parameters ---
  @@length = "800;900;1000;1100;1200"
  @@height = "100;200;300"
  @@thickness = 20.0
  @@randomize_thickness = false
  @@thickness_variation = "15;20;25" # Min;Base;Max thickness values
  @@joint_length = 3.0
  @@joint_width = 3.0
  @@color_name = "PARAMETRIX-LAYOUT"
  @@pattern_type = "running_bond"
  @@manual_unit = "auto"
  @@layout_start_direction = "center"
  @@start_row_height_index = 1
  @@randomize_lengths = true
  @@randomize_heights = false
  @@enable_min_piece_length = true
  @@min_piece_length = 300.0
  @@multi_face_mode = true # Always true for unified layout
  @@remove_small_pieces = false # DISABLED: Reactive removal causes gaps. Use proactive adjustment instead.
  @@synchronize_patterns = true
  @@unified_material = true # Not currently used in this version, but kept for future
  @@cavity_distance = 50.0
  @@force_horizontal_layout = true
  @@preserve_corners = true

  # --- Single-Row Layout Parameters (NEW) ---
  @@single_row_mode = false # Moved to Advanced tab
  @@single_row_length = "1000" # Default length for single row
  @@single_row_height = "620" # Default height for single row (was @@single_row_custom_height)
  @@single_row_thickness = 20.0
  @@single_row_randomize_thickness = false
  @@single_row_thickness_variation = "15;20;25"
  @@single_row_joint_length = 3.0
  @@single_row_joint_width = 3.0
  @@single_row_cavity_distance = 50.0
  @@single_row_pattern_type = "running_bond"
  @@single_row_randomize_lengths = false # New setting for single row
  @@single_row_min_piece_length = 300.0

  def self.filter_and_extend_pieces(pieces, min_piece_su, joint_length_su)
    # Remove pieces below minimum and extend adjacent pieces
    return pieces if pieces.empty? || min_piece_su <= 0
    
    filtered_pieces = []
    current_extension = 0.0
    
    pieces.each_with_index do |piece, index|
      piece_length = piece[:length]
      
      if piece_length < min_piece_su
        # Mark this piece for removal and accumulate its length
        current_extension += piece_length + joint_length_su
      else
        # This piece meets minimum - add accumulated extension to it
        if current_extension > 0.001
          piece[:length] += current_extension
          piece[:type] = "extended" if piece[:type] != "extended"
          current_extension = 0.0
        end
        filtered_pieces << piece
      end
    end
    
    # If we have leftover extension and pieces, add it to the last piece
    if current_extension > 0.001 && filtered_pieces.length > 0
      filtered_pieces.last[:length] += current_extension
      filtered_pieces.last[:type] = "extended"
    end
    
    return filtered_pieces
  end

  def self.is_single_length_mode?(length_values)
    return length_values.length == 1
  end

  def self.generate_single_length_row_with_min_piece(row_width, piece_length_su, joint_length_su, min_piece_su, unit_conversion)
    pieces = []
    current_pos = 0.0
    
    # Generate full pieces
    while current_pos + piece_length_su <= row_width
      pieces << { start: current_pos, length: piece_length_su, type: "full" }
      current_pos += piece_length_su + joint_length_su
    end
    
    remainder = row_width - current_pos
    
    # Check if minimum piece constraint is enabled
    constraint_enabled = @@single_row_mode ? true : @@enable_min_piece_length
    
    if remainder > 0.001
      if constraint_enabled && remainder < min_piece_su && pieces.length > 0
        # Merge small remainder with last piece
        last_piece = pieces.last
        adjustment = remainder + joint_length_su
        last_piece[:length] += adjustment
        last_piece[:type] = "adjusted"
      else
        # Add remainder as cut piece
        pieces << { start: current_pos, length: remainder, type: "cut" }
      end
    end
    
    return pieces
  end

  def self.generate_row_with_face_bounds_min_piece(row_start_x, row_width, local_bounds, length_values_su, joint_length_su, min_piece_su, unit_conversion, randomize = false)
    pieces = []
    current_pos = 0.0
    length_index = 0
    
    while current_pos < row_width
      current_length = randomize ? length_values_su[rand(length_values_su.length)] : length_values_su[length_index % length_values_su.length]
      
      if current_pos + current_length <= row_width
        # Check what the actual trimmed size would be
        piece_start_x = row_start_x + current_pos
        piece_end_x = piece_start_x + current_length
        
        intersect_left = [piece_start_x, local_bounds.min.x].max
        intersect_right = [piece_end_x, local_bounds.max.x].min
        actual_trimmed_width = intersect_right - intersect_left
        
        if actual_trimmed_width >= min_piece_su || min_piece_su == 0
          pieces << { start: current_pos, length: current_length, type: "full" }
          current_pos += current_length + joint_length_su
          length_index += 1 unless randomize
        else
          # This piece would be too small after trimming - extend previous piece
          if pieces.length > 0
            last_piece = pieces.last
            extension = (row_width - last_piece[:start])
            last_piece[:length] = extension
            last_piece[:type] = "extended"
          end
          break
        end
      else
        remainder = row_width - current_pos
        if remainder > 0.001
          # Check if remainder would be too small after trimming
          piece_start_x = row_start_x + current_pos
          piece_end_x = piece_start_x + remainder
          
          intersect_left = [piece_start_x, local_bounds.min.x].max
          intersect_right = [piece_end_x, local_bounds.max.x].min
          actual_trimmed_width = intersect_right - intersect_left
          
          if actual_trimmed_width >= min_piece_su || min_piece_su == 0
            pieces << { start: current_pos, length: remainder, type: "cut" }
          elsif pieces.length > 0
            # Extend last piece to fill the gap
            last_piece = pieces.last
            extension = remainder + joint_length_su
            last_piece[:length] += extension
            last_piece[:type] = "extended"
          end
        end
        break
      end
    end
    
    return pieces
  end

  def self.generate_multi_length_row_with_min_piece(row_width, length_values_su, joint_length_su, min_piece_su, unit_conversion, randomize = false)
    # First pass: generate pieces normally to see what we get
    temp_pieces = []
    current_pos = 0.0
    length_index = 0
    
    while current_pos < row_width
      current_length = randomize ? length_values_su[rand(length_values_su.length)] : length_values_su[length_index % length_values_su.length]
      
      if current_pos + current_length <= row_width
        temp_pieces << current_length
        current_pos += current_length + joint_length_su
        length_index += 1 unless randomize
      else
        remainder = row_width - current_pos
        if remainder > 0.001
          temp_pieces << remainder
        end
        break
      end
    end
    
    # Check if minimum piece constraint is enabled and last piece is too small
    constraint_enabled = @@single_row_mode ? true : @@enable_min_piece_length
    
    if constraint_enabled && temp_pieces.length > 1 && temp_pieces.last < min_piece_su
      # Distribute the small piece among adjacent pieces
      small_piece = temp_pieces.pop
      if temp_pieces.length > 0
        # Add to previous piece
        temp_pieces[-1] += small_piece + joint_length_su
      end
    end
    
    # Convert to final pieces with positions
    pieces = []
    current_pos = 0.0
    temp_pieces.each do |length|
      pieces << { start: current_pos, length: length, type: length == temp_pieces.first || length == temp_pieces.last ? "edge" : "full" }
      current_pos += length + joint_length_su
    end
    
    return pieces
  end

  # --- Rail parameters ---
  @@enable_top_rail = true
  @@enable_bottom_rail = true
  @@enable_left_rail = false
  @@enable_right_rail = false
  @@top_rail_thickness = 20.0
  @@top_rail_depth = 300.0
  @@bottom_rail_thickness = 20.0
  @@bottom_rail_depth = 300.0
  @@left_rail_thickness = 20.0
  @@left_rail_depth = 300.0
  @@right_rail_thickness = 20.0
  @@right_rail_depth = 300.0
  @@rail_color_name = "PARAMETRIX-RAILS"
  @@split_rails = false
  
  # Real-time generation settings (Not currently used in this version, but kept for future)
  @@enable_realtime_generation = true
  @@generation_delay = 0.01
  @@show_confirmation_popup = false
  
  # Preview tracking
  @@preview_group = nil
  @@current_dialog = nil
  @@current_multi_face_position = nil
  @@realtime_timer = nil

  def self.get_unit_name
    unit = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]
    unit_names = ["inches", "feet", "mm", "cm", "m"]
    unit_names[unit] || "cm"
  end

  def self.get_unit_conversion
    unit = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]
    conversions = [1.0, 12.0, 0.1/2.54, 1.0/2.54, 100.0/2.54]
    return conversions[unit] if unit >= 0 && unit <= 4
    1.0/2.54
  end

  def self.get_effective_unit
    if @@manual_unit == "auto"
      get_unit_name
    else
      @@manual_unit
    end
  end

  def self.get_effective_unit_conversion
    unit = get_effective_unit
    case unit
    when "mm"
      0.1/2.54
    when "cm"
      1.0/2.54
    when "m"
      100.0/2.54
    when "feet"
      12.0
    when "inches"
      1.0
    else
      get_unit_conversion
    end
  end

  def self.analyze_multi_face_selection(selection)
    faces_data = []
    selection.each do |entity|
      if entity.is_a?(Sketchup::Face)
        faces_data << { face: entity, matrix: Geom::Transformation.new, source: "direct" }
      elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        entity.definition.entities.each do |sub_entity|
          if sub_entity.is_a?(Sketchup::Face)
            faces_data << { face: sub_entity, matrix: entity.transformation, source: "group/component" }
          end
        end
      end
    end
    return faces_data
  end

  def self.validate_faces_for_processing(faces_data)
    return false if faces_data.empty?

    valid_faces = faces_data.select { |data| data[:face] && data[:face].valid? }

    if valid_faces.length != faces_data.length
      puts "[PARAMETRIX] Validation failed: Some faces are invalid"
      return false
    end

    unit_conversion = get_effective_unit_conversion
    min_area = (100.0 * unit_conversion) ** 2

    valid_faces.each_with_index do |data, index|
      face = data[:face]
      area = face.area

      if area < min_area
        puts "[PARAMETRIX] Validation failed: Face #{index + 1} area too small (#{area.round(2)} < #{min_area.round(2)})"
        return false
      end
      
      # Check for through-holes (multiple inner loops)
      if face.loops.length > 2
        puts "[PARAMETRIX] Warning: Face #{index + 1} has #{face.loops.length - 1} holes. Complex geometry may cause issues."
      end
      
      # Check for degenerate edges
      degenerate_edges = 0
      face.outer_loop.edges.each do |edge|
        if edge.length < 0.001
          degenerate_edges += 1
        end
      end
      
      if degenerate_edges > 0
        puts "[PARAMETRIX] Warning: Face #{index + 1} has #{degenerate_edges} degenerate edges"
      end
    end
    return true
  end

  def self.get_proper_active_context
    model = Sketchup.active_model

    if model.active_path && model.active_path.length > 0
      active_entities = model.active_entities
      context_parts = []
      model.active_path.each_with_index do |entity, index|
        if entity.is_a?(Sketchup::Group)
          context_parts << "Group[#{index}]"
        elsif entity.is_a?(Sketchup::ComponentInstance)
          context_parts << "Component[#{index}]:#{entity.definition.name}"
        end
      end
      context_name = "Nested: #{context_parts.join(' > ')}"
      return [active_entities, context_name]
    else
      return [model.entities, "Model"]
    end
  end

  def self.detect_corner_type(face, face_matrix, all_faces_data)
    face_normal = face.normal
    if face_matrix && face_matrix != Geom::Transformation.new
      face_normal = face_normal.transform(face_matrix)
    end
    
    adjacent_faces = 0
    all_faces_data.each do |other_data|
      next if other_data[:face] == face
      
      other_normal = other_data[:face].normal
      if other_data[:matrix] && other_data[:matrix] != Geom::Transformation.new
        other_normal = other_normal.transform(other_data[:matrix])
      end
      
      dot_product = face_normal.dot(other_normal)
      if dot_product.abs < 0.1
        adjacent_faces += 1
      end
    end
    
    corner_type = adjacent_faces > 0 ? "internal" : "external"
    
    return corner_type
  end

  def self.calculate_cavity_offset_with_corner_logic(original_face, face_matrix, cavity_distance_su, face_index, corner_type)
    original_face_normal = original_face.normal
    if face_matrix && face_matrix != Geom::Transformation.new
      original_face_normal = original_face_normal.transform(face_matrix)
    end

    outward_normal = original_face_normal.clone
    outward_normal.normalize!

    cavity_offset = outward_normal.clone
    cavity_offset.length = cavity_distance_su

    return { cavity_offset: cavity_offset, original_normal: original_face_normal, outward_normal: outward_normal, corner_type: corner_type }
  end

  def self.create_virtual_extended_bounds(face, face_matrix, cavity_distance_su, face_index, all_faces_data)
    face_bounds = face.bounds
    if face_matrix && face_matrix != Geom::Transformation.new
      min_pt = face_bounds.min.transform(face_matrix)
      max_pt = face_bounds.max.transform(face_matrix)
      face_center = Geom::Point3d.new(
        (min_pt.x + max_pt.x) / 2.0,
        (min_pt.y + max_pt.y) / 2.0,
        (min_pt.z + max_pt.z) / 2.0
      )
    else
      face_center = face_bounds.center
    end

    corner_type = detect_corner_type(face, face_matrix, all_faces_data)
    cavity_data = calculate_cavity_offset_with_corner_logic(face, face_matrix, cavity_distance_su, face_index, corner_type)
    cavity_offset = cavity_data[:cavity_offset]
    original_normal = cavity_data[:original_normal]
    outward_normal = cavity_data[:outward_normal]

    face_center_with_cavity = face_center.offset(cavity_offset)

    return { 
      face_center_with_cavity: face_center_with_cavity, 
      original_normal: original_normal, 
      outward_normal: outward_normal,
      cavity_offset: cavity_offset,
      corner_type: corner_type
    }
  end

  def self.get_face_transformation_matrix_user_logic(face, face_matrix, cavity_distance_su, face_index, all_faces_data)
    face_normal = face.normal
    if face_matrix && face_matrix != Geom::Transformation.new
      face_normal = face_normal.transform(face_matrix)
    end

    bounds_data = create_virtual_extended_bounds(face, face_matrix, cavity_distance_su, face_index, all_faces_data)
    face_center_with_cavity = bounds_data[:face_center_with_cavity]
    original_normal = bounds_data[:original_normal]
    outward_normal = bounds_data[:outward_normal]
    corner_type = bounds_data[:corner_type]

    if @@force_horizontal_layout
      face_normal_abs = Geom::Vector3d.new(face_normal.x.abs, face_normal.y.abs, face_normal.z.abs)

      if face_normal_abs.z > 0.8
        x_axis = Geom::Vector3d.new(1, 0, 0)
        y_axis = Geom::Vector3d.new(0, 1, 0)
      elsif face_normal_abs.y > 0.8
        x_axis = Geom::Vector3d.new(1, 0, 0)
        y_axis = Geom::Vector3d.new(0, 0, 1)
      elsif face_normal_abs.x > 0.8
        x_axis = Geom::Vector3d.new(0, 1, 0)
        y_axis = Geom::Vector3d.new(0, 0, 1)
      else
        horizontal_normal = Geom::Vector3d.new(face_normal.x, face_normal.y, 0)
        if horizontal_normal.length > 0.001
          horizontal_normal.normalize!
          x_axis = horizontal_normal.cross(Geom::Vector3d.new(0, 0, 1))
          y_axis = Geom::Vector3d.new(0, 0, 1)
        else
          x_axis = Geom::Vector3d.new(1, 0, 0)
          y_axis = Geom::Vector3d.new(0, 0, 1)
        end
      end
    else
      longest_edge = nil
      max_length = 0.0

      face.outer_loop.edges.each do |edge|
        if edge.length > max_length
          max_length = edge.length
          longest_edge = edge
        end
      end

      if longest_edge
        x_axis = longest_edge.line[1].normalize
        if face_matrix && face_matrix != Geom::Transformation.new
          x_axis = x_axis.transform(face_matrix)
        end
      else
        if face_normal.parallel?(Geom::Vector3d.new(0, 0, 1))
          x_axis = Geom::Vector3d.new(1, 0, 0)
        else
          x_axis = face_normal.cross(Geom::Vector3d.new(0, 0, 1)).normalize
        end
      end

      y_axis = face_normal.cross(x_axis).normalize
    end

    face_transform = Geom::Transformation.axes(face_center_with_cavity, x_axis, y_axis, face_normal)

    return { 
      transform: face_transform, 
      original_normal: original_normal,
      outward_normal: outward_normal,
      corner_type: corner_type,
      x_axis: x_axis,
      y_axis: y_axis
    }
  end

  def self.get_face_local_bounds_with_fixed_extension(face, face_matrix, face_transform, cavity_distance_su, face_index, corner_type)
    vertices = []
    face.outer_loop.vertices.each do |vertex|
      pt = vertex.position
      if face_matrix && face_matrix != Geom::Transformation.new
        pt = pt.transform(face_matrix)
      end
      local_pt = pt.transform(face_transform.inverse)
      vertices << local_pt
    end

    local_bounds = Geom::BoundingBox.new
    vertices.each { |pt| local_bounds.add(pt) }

    # Apply corner extension: cavity_distance - thickness to compensate for gap
    if @@preserve_corners && cavity_distance_su > 0.001
      unit_conversion = get_effective_unit_conversion
      thickness_su = @@single_row_mode ? @@single_row_thickness * unit_conversion : @@thickness * unit_conversion
      corner_extension = cavity_distance_su - thickness_su
      corner_extension = [corner_extension, 0.0].max

      extended_bounds = Geom::BoundingBox.new
      extended_bounds.add([
        local_bounds.min.x - corner_extension,
        local_bounds.min.y - corner_extension,
        local_bounds.min.z
      ])
      extended_bounds.add([
        local_bounds.max.x + corner_extension,
        local_bounds.max.y + corner_extension,
        local_bounds.max.z
      ])

      return extended_bounds
    end
    
    return local_bounds
  end

  def self.calculate_global_unified_bounds(all_faces_data, cavity_distance_su)
    face_transforms = []
    
    all_faces_data.each_with_index do |face_data, face_index|
      face = face_data[:face]
      face_matrix = face_data[:matrix]
      
      corner_type = detect_corner_type(face, face_matrix, all_faces_data)
      transform_data = get_face_transformation_matrix_user_logic(face, face_matrix, cavity_distance_su, face_index, all_faces_data)
      face_transform = transform_data[:transform]
      original_normal = transform_data[:original_normal]
      local_bounds = get_face_local_bounds_with_fixed_extension(face, face_matrix, face_transform, cavity_distance_su, face_index, corner_type)
      
      face_transforms << {
        face_data: face_data,
        transform: face_transform,
        local_bounds: local_bounds,
        corner_type: corner_type,
        original_normal: original_normal,
        x_axis: transform_data[:x_axis],
        y_axis: transform_data[:y_axis]
      }
    end
    
    # Use first face bounds as global bounds for single face
    first_bounds = face_transforms[0][:local_bounds]
    unified_bounds = Geom::BoundingBox.new
    unified_bounds.add(first_bounds.min)
    unified_bounds.add(first_bounds.max)
    
    unified_transform = Geom::Transformation.new
    
    return {
      global_bounds: unified_bounds,
      reference_transform: unified_transform,
      face_transforms: face_transforms
    }
  end

  def self.calculate_unified_start_position(global_bounds, avg_length_su, avg_height_su, joint_length_su, joint_width_su, single_row_mode)
    layout_width = global_bounds.width
    layout_height = global_bounds.height

    elements_x = ((layout_width + joint_length_su) / (avg_length_su + joint_length_su)).ceil + 6
    
    if single_row_mode
      elements_y = 1 # Force to 1 row
      effective_layout_height_for_pattern = avg_height_su 
    else
      elements_y = ((layout_height + joint_width_su) / (avg_height_su + joint_width_su)).ceil + 6
      effective_layout_height_for_pattern = layout_height
    end

    total_pattern_width = elements_x * avg_length_su + (elements_x - 1) * joint_length_su
    total_pattern_height = elements_y * avg_height_su + (elements_y - 1) * joint_width_su

    # Reduced margins to prevent elements from being placed outside bounds
    margin_x = avg_length_su * 0.5
    margin_y = avg_height_su * 0.5
    
    case @@layout_start_direction
    when "top_left"
      start_x = global_bounds.min.x - margin_x
      start_y = global_bounds.max.y + margin_y
    when "top"
      start_x = global_bounds.min.x + (layout_width - total_pattern_width) / 2.0
      start_y = global_bounds.max.y + margin_y
    when "top_right"
      start_x = global_bounds.max.x - total_pattern_width + margin_x
      start_y = global_bounds.max.y + margin_y
    when "left"
      start_x = global_bounds.min.x - margin_x
      start_y = global_bounds.min.y + (layout_height - total_pattern_height) / 2.0
    when "center"
      start_x = global_bounds.min.x + (layout_width - total_pattern_width) / 2.0
      start_y = global_bounds.min.y + (layout_height - total_pattern_height) / 2.0
    when "right"
      start_x = global_bounds.max.x - total_pattern_width + margin_x
      start_y = global_bounds.min.y + (layout_height - total_pattern_height) / 2.0
    when "bottom_left"
      start_x = global_bounds.min.x - margin_x
      start_y = global_bounds.min.y - margin_y
    when "bottom"
      start_x = global_bounds.min.x + (layout_width - total_pattern_width) / 2.0
      start_y = global_bounds.min.y - margin_y
    when "bottom_right"
      start_x = global_bounds.max.x - total_pattern_width + margin_x
      start_y = global_bounds.min.y - margin_y
    else # fallback to center
      start_x = global_bounds.min.x + (layout_width - total_pattern_width) / 2.0
      start_y = global_bounds.min.y + (layout_height - total_pattern_height) / 2.0
    end

    unit_conversion = get_effective_unit_conversion
    unit_name = get_effective_unit

    return [start_x, start_y, elements_x, elements_y]
  end

  def self.parse_multi_values(value_string, randomize = false)
    return [] if value_string.nil? || value_string.strip.empty?

    cleaned = value_string.to_s.strip

    if cleaned.include?(';')
      values = cleaned.split(';').map { |v| v.strip.to_f }.select { |v| v > 0 }
      values = values.shuffle if randomize && values.length > 1
      values
    else
      single_val = cleaned.to_f
      single_val > 0 ? [single_val] : []
    end
  end

  def self.get_random_thickness(unit_conversion, single_row_mode = false)
    # Get thickness settings based on mode
    if single_row_mode
      return @@single_row_thickness * unit_conversion unless @@single_row_randomize_thickness
      thickness_string = @@single_row_thickness_variation
    else
      return @@thickness * unit_conversion unless @@randomize_thickness
      thickness_string = @@thickness_variation
    end
    
    # Parse thickness variation values
    thickness_values = parse_multi_values(thickness_string)
    return @@thickness * unit_conversion if thickness_values.empty?
    
    # Return random thickness from the range
    random_thickness = thickness_values[rand(thickness_values.length)]
    return random_thickness * unit_conversion
  end

  def self.get_height_values_with_start_index(height_values, start_index)
    # FIXED: Clearer implementation with explicit documentation
    # This function rotates the height pattern to start from a specific index
    # start_index is 1-based (user-friendly), so index 1 = first element
    
    return height_values if height_values.length <= 1
    
    # Validate start_index is within bounds
    if start_index <= 0 || start_index > height_values.length
      # Invalid index - return original pattern
      return height_values
    end
    
    # Convert 1-based user index to 0-based array index
    array_index = start_index - 1
    
    # Rotate array: take elements from array_index to end, then prepend elements from start to array_index
    rotated_pattern = height_values[array_index..-1] + height_values[0...array_index]
    
    return rotated_pattern
  end
  
  def self.create_materials(color_name, rail_color_name = nil)
    materials_array = []
    model = Sketchup.active_model
    materials = model.materials

    base_material = materials[color_name]
    unless base_material
      base_material = materials.add(color_name)
      base_material.color = Sketchup::Color.new(122, 122, 122)
    end
    materials_array << base_material

    if rail_color_name
      rail_material = materials[rail_color_name]
      unless rail_material
        rail_material = materials.add(rail_color_name)
        rail_material.color = Sketchup::Color.new(80, 80, 80)
      end
      materials_array << rail_material
    end

    materials_array
  end

  def self.remove_preview
    if @@preview_group && @@preview_group.valid?
      model = Sketchup.active_model
      model.entities.erase_entities(@@preview_group)
      puts "[PARAMETRIX] Previous preview removed"
    end
    @@preview_group = nil
  end

  def self.create_piece_with_ghosting(face_group, world_points, materials, thickness_su, original_normal, piece_index, total_pieces, is_preview = false, original_face = nil, face_matrix = nil, use_random_thickness = false, unit_conversion = 1.0, single_row_mode = false)
    begin
      face_element = face_group.entities.add_face(world_points)
      if face_element
        # Store thickness data for LATER extrusion (after 2D trimming)
        final_thickness = use_random_thickness ? get_random_thickness(unit_conversion, single_row_mode) : thickness_su
        
        if is_preview
          preview_thickness = final_thickness * 0.5
          face_element.set_attribute('PARAMETRIX_DATA', 'thickness', preview_thickness)
          face_element.material = "#AAAAAA"
          face_element.back_material = "#AAAAAA"
        else
          face_element.set_attribute('PARAMETRIX_DATA', 'thickness', final_thickness)
          face_element.material = materials.first
          face_element.back_material = materials.first
        end
        
        face_element.set_attribute('PARAMETRIX_DATA', 'original_normal', original_normal)
        
        # NO PUSHPULL HERE - Return 2D face for trimming first
        return true
      end
    rescue => e
      puts "[PARAMETRIX] Error creating piece: #{e.message}"
      return false
    end
  end

  def self.trim_piece_to_face_boundary(piece_face, original_face, face_matrix)
    begin
      # Get original face boundary points in world coordinates
      boundary_points = []
      original_face.outer_loop.vertices.each do |vertex|
        pt = vertex.position
        if face_matrix && face_matrix != Geom::Transformation.new
          pt = pt.transform(face_matrix)
        end
        boundary_points << pt
      end
      
      # Get piece face vertices
      piece_vertices = piece_face.outer_loop.vertices.map { |v| v.position }
      
      # Check if piece center is inside original face boundary
      piece_center = piece_face.bounds.center
      
      # Simple point-in-polygon test using ray casting
      if point_in_polygon?(piece_center, boundary_points)
        # Piece is inside - keep it
        return piece_face
      else
        # Piece is outside - check for intersection
        intersection_points = []
        
        # Find intersection points between piece edges and boundary
        piece_vertices.each_with_index do |v1, i|
          v2 = piece_vertices[(i + 1) % piece_vertices.length]
          
          boundary_points.each_with_index do |b1, j|
            b2 = boundary_points[(j + 1) % boundary_points.length]
            
            intersection = line_intersect_2d(v1, v2, b1, b2)
            if intersection
              intersection_points << intersection
            end
          end
        end
        
        # If we have intersection points, create trimmed piece
        if intersection_points.length >= 3
          # Remove duplicate points
          unique_points = intersection_points.uniq { |pt| [pt.x.round(6), pt.y.round(6)] }
          
          if unique_points.length >= 3
            trimmed_face = piece_face.parent.entities.add_face(unique_points)
            piece_face.parent.entities.erase_entities(piece_face)
            return trimmed_face
          end
        end
        
        # No valid intersection - remove piece
        piece_face.parent.entities.erase_entities(piece_face)
        return nil
      end
      
    rescue => e
      puts "[PARAMETRIX] Trimming failed: #{e.message}"
      return piece_face
    end
  end
  
  def self.create_cutting_component_from_layout_NEW_METHOD(layout_group, original_face, face_matrix)
    begin
      puts "[PARAMETRIX] NEW OOB METHOD CALLED - STARTING BOOLEAN TRIMMING"
      model = Sketchup.active_model
      ents = model.active_entities
      
      # Exact Oob boolean2d method
      gp = ents.add_group
      gents = gp.entities
      oob_face_clone(gents, [original_face], face_matrix)
      
      # Get cloned face
      oface = nil
      gents.each { |e| oface = e if e.is_a?(Sketchup::Face) }
      return layout_group unless oface
      
      # Intersect - exact Oob method
      tr = Geom::Transformation.new
      gptr = gp.transformation
      cents = layout_group.entities
      
      cents.intersect_with(false, gptr, cents, tr, false, [gp])
      cents.intersect_with(false, gptr, cents, tr, false, [gp])
      
      gp2ptogo = []
      
      # Collect edges - exact Oob logic
      cents.to_a.each do |edge|
        if edge.is_a?(Sketchup::Edge)
          if oface.classify_point(edge.start) == Sketchup::Face::PointOutside &&
             oface.classify_point(edge.end) == Sketchup::Face::PointOutside
            gp2ptogo << edge
          end
          
          # Offset point to middle of edge and test
          if oface.classify_point(edge.start.position.offset(edge.line[1], edge.length/2)) == Sketchup::Face::PointOutside
            gp2ptogo << edge
          end
        end
      end
      
      cents.erase_entities(gp2ptogo)
      
      # Remove faces in holes - exact Oob logic
      faces2go2 = []
      cents.to_a.each do |gface|
        if gface.is_a?(Sketchup::Face)
          hole = true
          gface.outer_loop.edges.each do |e|
            if e.faces.length == 1
              hole = false
              break
            end
          end
          next unless hole
          
          pt = gface.bounds.center.project_to_plane(oface.plane)
          if oface.classify_point(pt) == Sketchup::Face::PointOutside
            faces2go2 << gface
          end
        end
      end
      
      cents.erase_entities(faces2go2)
      gp.erase!
      
      puts "[PARAMETRIX] Oob method: removed #{gp2ptogo.length} edges, #{faces2go2.length} faces"
      
      # Convert to component
      inst = layout_group.to_component
      defn = inst.definition
      be = defn.behavior
      
      be.is2d = true
      be.cuts_opening = true
      defn.invalidate_bounds
      
      inst.name = "PARAMETRIX Layout Cut"
      defn.name = "PARAMETRIX Layout Cut Def"
      
      return inst
      
    rescue => e
      puts "[PARAMETRIX] Boolean trimming failed: #{e.message}"
      return layout_group
    end
  end
  
  def self.oob_face_clone(gents, faces, face_matrix)
    faces2go = []
    
    faces.each do |face|
      # Create face from each loop
      face.loops.each { |loop| gents.add_face(loop.vertices) }
      oface = gents.add_face(face.outer_loop.vertices) # Make outer face again
      
      # Find inner faces to erase
      gents.each do |face_ent|
        next unless face_ent.is_a?(Sketchup::Face)
        face_ent.edges.each do |e|
          unless e.faces[1] # Edge bordered by only one face
            break
          end
          faces2go << face_ent # All edges bordered by 2 faces = inner face
        end
      end
      gents.erase_entities(faces2go) # Remove inner faces to create holes
    end
  end
  
  def self.face_clone(gents, face, face_matrix)
    # Clone outer loop
    ov = []
    face.outer_loop.vertices.each do |v|
      pt = v.position
      if face_matrix && face_matrix != Geom::Transformation.new
        pt = pt.transform(face_matrix)
      end
      ov.push(pt)
    end
    outer_face = gents.add_face(ov)
    
    # Clone inner loops (holes)
    inner_faces = []
    if face.loops.length > 1
      il = face.loops.dup
      il.shift # Remove outer loop
      il.each do |loop|
        iv = []
        loop.vertices.each do |v|
          pt = v.position
          if face_matrix && face_matrix != Geom::Transformation.new
            pt = pt.transform(face_matrix)
          end
          iv.push(pt)
        end
        inner_face = gents.add_face(iv)
        inner_faces.push(inner_face)
      end
      # Erase inner faces to create holes
      inner_faces.each { |f| f.erase! }
    end
    
    return outer_face
  end



  def self.show_license_info
    PARAMETRIX::LicenseDialog.show
  end

  def self.check_for_updates
    UI.messagebox("Update checking functionality will be implemented in a future version.", MB_OK, "Check for Updates")
  end

  def self.contact_support
    PARAMETRIX::SupportDialog.show
  end

  def self.detect_rail_end_corner_type(local_pt, rail_orientation, local_bounds, tolerance = 0.1)
    at_left = (local_pt.x - local_bounds.min.x).abs < tolerance
    at_right = (local_pt.x - local_bounds.max.x).abs < tolerance
    at_bottom = (local_pt.y - local_bounds.min.y).abs < tolerance
    at_top = (local_pt.y - local_bounds.max.y).abs < tolerance
    
    case rail_orientation
    when :top
      return :external_miter if at_left || at_right
    when :bottom
      return :external_miter if at_left || at_right
    when :left
      return :external_miter if at_top || at_bottom
    when :right
      return :external_miter if at_top || at_bottom
    end
    
    :butt_end
  end

  def self.create_mitered_rail_points(edge_data, rail_start_y, rail_end_y, rail_thickness, local_bounds, is_horizontal)
    local_p1 = edge_data[:local_p1]
    local_p2 = edge_data[:local_p2]
    orientation = edge_data[:orientation]
    
    if is_horizontal
      p1 = Geom::Point3d.new(local_p1.x, rail_start_y, 0)
      p2 = Geom::Point3d.new(local_p2.x, rail_start_y, 0)
      p3 = Geom::Point3d.new(local_p2.x, rail_end_y, 0)
      p4 = Geom::Point3d.new(local_p1.x, rail_end_y, 0)
      
      left_corner = detect_rail_end_corner_type(local_p1, orientation, local_bounds)
      right_corner = detect_rail_end_corner_type(local_p2, orientation, local_bounds)
      
      if left_corner == :external_miter
        if orientation == :top
          p4 = Geom::Point3d.new(local_p1.x + rail_thickness, rail_end_y, 0)
        else
          p1 = Geom::Point3d.new(local_p1.x + rail_thickness, rail_start_y, 0)
        end
      end
      
      if right_corner == :external_miter
        if orientation == :top
          p3 = Geom::Point3d.new(local_p2.x - rail_thickness, rail_end_y, 0)
        else
          p2 = Geom::Point3d.new(local_p2.x - rail_thickness, rail_start_y, 0)
        end
      end
    else
      p1 = Geom::Point3d.new(rail_start_y, local_p1.y, 0)
      p2 = Geom::Point3d.new(rail_start_y, local_p2.y, 0)
      p3 = Geom::Point3d.new(rail_end_y, local_p2.y, 0)
      p4 = Geom::Point3d.new(rail_end_y, local_p1.y, 0)
      
      bottom_corner = detect_rail_end_corner_type(local_p1, orientation, local_bounds)
      top_corner = detect_rail_end_corner_type(local_p2, orientation, local_bounds)
      
      if bottom_corner == :external_miter
        if orientation == :left
          p1 = Geom::Point3d.new(rail_start_y, local_p1.y + rail_thickness, 0)
        else
          p4 = Geom::Point3d.new(rail_end_y, local_p1.y + rail_thickness, 0)
        end
      end
      
      if top_corner == :external_miter
        if orientation == :left
          p2 = Geom::Point3d.new(rail_start_y, local_p2.y - rail_thickness, 0)
        else
          p3 = Geom::Point3d.new(rail_end_y, local_p2.y - rail_thickness, 0)
        end
      end
    end
    
    [p1, p2, p3, p4]
  end

  def self.find_perpendicular_face_at_corner(face_data, all_faces_data, corner_edge_local, face_transform)
    # Check if this corner edge connects to a perpendicular face
    face = face_data[:face]
    face_matrix = face_data[:matrix]
    face_normal = face.normal.transform(face_matrix)
    
    all_faces_data.each do |other_data|
      next if other_data[:face] == face
      other_normal = other_data[:face].normal.transform(other_data[:matrix])
      
      # Check if perpendicular (dot product near 0)
      if (face_normal.dot(other_normal)).abs < 0.1
        # Check if they share an edge in world space
        world_p1 = corner_edge_local[:local_p1].transform(face_transform)
        world_p2 = corner_edge_local[:local_p2].transform(face_transform)
        
        other_data[:face].edges.each do |other_edge|
          other_p1 = other_edge.start.position.transform(other_data[:matrix])
          other_p2 = other_edge.end.position.transform(other_data[:matrix])
          
          # Check if edges share vertices (within tolerance)
          if (world_p1.distance(other_p1) < 1.0 || world_p1.distance(other_p2) < 1.0) &&
             (world_p2.distance(other_p1) < 1.0 || world_p2.distance(other_p2) < 1.0)
            return true
          end
        end
      end
    end
    false
  end

  def self.create_rails_for_face(face_data, main_group, face_group, rail_material, unit_conversion, face_index, cavity_distance_su, all_faces_data, local_bounds, face_transform, original_normal, single_row_mode, stone_min_y_for_rails, stone_max_y_for_rails, joint_width_su)
    puts "[RAILS] create_rails_for_face called for face #{face_index + 1}"
    puts "[RAILS] Enabled: top=#{@@enable_top_rail}, bottom=#{@@enable_bottom_rail}, left=#{@@enable_left_rail}, right=#{@@enable_right_rail}"
    return nil unless @@enable_top_rail || @@enable_bottom_rail || @@enable_left_rail || @@enable_right_rail

    top_rail_thickness_su = @@top_rail_thickness * unit_conversion
    top_rail_depth_su = @@top_rail_depth * unit_conversion
    bottom_rail_thickness_su = @@bottom_rail_thickness * unit_conversion
    bottom_rail_depth_su = @@bottom_rail_depth * unit_conversion
    left_rail_thickness_su = @@left_rail_thickness * unit_conversion
    left_rail_depth_su = @@left_rail_depth * unit_conversion
    right_rail_thickness_su = @@right_rail_thickness * unit_conversion
    right_rail_depth_su = @@right_rail_depth * unit_conversion

    created_rails = []
    inv_transform = face_transform.inverse

    layout_ents = face_group.is_a?(Sketchup::ComponentInstance) ? face_group.definition.entities : face_group.entities
    trimmed_faces = layout_ents.grep(Sketchup::Face)
    puts "[RAILS] Found #{trimmed_faces.length} trimmed faces"
    return nil if trimmed_faces.empty?

    all_edges = []
    trimmed_faces.each { |f| all_edges.concat(f.edges) }
    all_edges.uniq!
    puts "[RAILS] Found #{all_edges.length} unique edges"

    # RECALCULATE actual stone bounds from trimmed faces
    actual_min_y = Float::INFINITY
    actual_max_y = -Float::INFINITY
    actual_min_x = Float::INFINITY
    actual_max_x = -Float::INFINITY
    
    trimmed_faces.each do |face|
      face.vertices.each do |vertex|
        local_pt = vertex.position.transform(inv_transform)
        actual_min_y = [actual_min_y, local_pt.y].min
        actual_max_y = [actual_max_y, local_pt.y].max
        actual_min_x = [actual_min_x, local_pt.x].min
        actual_max_x = [actual_max_x, local_pt.x].max
      end
    end
    
    puts "[RAILS] Actual stone bounds: x=[#{actual_min_x.round(2)}, #{actual_max_x.round(2)}], y=[#{actual_min_y.round(2)}, #{actual_max_y.round(2)}]"
    puts "[RAILS] Input stone bounds: y=[#{stone_min_y_for_rails.round(2)}, #{stone_max_y_for_rails.round(2)}]"

    classified_edges = []
    all_edges.each do |edge|
      local_p1 = edge.start.position.transform(inv_transform)
      local_p2 = edge.end.position.transform(inv_transform)
      
      dir = (local_p2 - local_p1).normalize
      angle = Math.atan2(dir.y, dir.x) * 180 / Math::PI
      angle = angle % 360
      
      orientation = if angle.between?(45, 135)
        :top
      elsif angle.between?(225, 315)
        :bottom
      elsif angle.between?(135, 225)
        :left
      else
        :right
      end
      
      classified_edges << { local_p1: local_p1, local_p2: local_p2, orientation: orientation }
    end

    # Debug: Show edge orientation distribution
    orientation_count = { top: 0, bottom: 0, left: 0, right: 0 }
    classified_edges.each { |e| orientation_count[e[:orientation]] += 1 }
    puts "[RAILS] Edge orientation distribution: #{orientation_count.inspect}"

    if @@enable_top_rail
      top_edges = classified_edges.select { |e| 
        (e[:local_p1].y - actual_max_y).abs < 0.5 || (e[:local_p2].y - actual_max_y).abs < 0.5
      }
      puts "[RAILS] Top rail: found #{top_edges.length} edges at y=#{actual_max_y.round(2)}"
      
      # Group continuous edges
      continuous_segments = []
      top_edges.sort_by { |e| [e[:local_p1].x, e[:local_p2].x].min }.each do |edge_data|
        if continuous_segments.empty?
          continuous_segments << [edge_data]
        else
          last_segment = continuous_segments.last
          last_edge = last_segment.last
          gap = [edge_data[:local_p1].x, edge_data[:local_p2].x].min - [last_edge[:local_p1].x, last_edge[:local_p2].x].max
          
          if gap < 1.0
            last_segment << edge_data
          else
            continuous_segments << [edge_data]
          end
        end
      end
      
      continuous_segments.each do |segment|
        min_x = segment.map { |e| [e[:local_p1].x, e[:local_p2].x].min }.min
        max_x = segment.map { |e| [e[:local_p1].x, e[:local_p2].x].max }.max
        
        # Check corners for perpendicular faces
        left_has_perp = find_perpendicular_face_at_corner(face_data, all_faces_data, 
          {local_p1: Geom::Point3d.new(min_x, actual_max_y, 0), local_p2: Geom::Point3d.new(min_x, actual_max_y, 0)}, face_transform)
        right_has_perp = find_perpendicular_face_at_corner(face_data, all_faces_data,
          {local_p1: Geom::Point3d.new(max_x, actual_max_y, 0), local_p2: Geom::Point3d.new(max_x, actual_max_y, 0)}, face_transform)
        
        rail_start_y = actual_max_y + joint_width_su
        rail_end_y = rail_start_y + top_rail_thickness_su
        
        p1 = Geom::Point3d.new(min_x, rail_start_y, 0)
        p2 = Geom::Point3d.new(max_x, rail_start_y, 0)
        p3 = Geom::Point3d.new(max_x, rail_end_y, 0)
        p4 = Geom::Point3d.new(min_x, rail_end_y, 0)
        
        # Extend at corners with perpendicular faces
        if left_has_perp
          p1 = Geom::Point3d.new(min_x - top_rail_thickness_su, rail_start_y, 0)
          p4 = Geom::Point3d.new(min_x - top_rail_thickness_su, rail_end_y, 0)
        end
        if right_has_perp
          p2 = Geom::Point3d.new(max_x + top_rail_thickness_su, rail_start_y, 0)
          p3 = Geom::Point3d.new(max_x + top_rail_thickness_su, rail_end_y, 0)
        end
        
        rail_group = main_group.entities.add_group
        rail_face = rail_group.entities.add_face([p1, p2, p3, p4].map { |pt| pt.transform(face_transform) }) rescue nil
        if rail_face
          rail_face.material = rail_material
          rail_face.back_material = rail_material
          pushpull_dist = rail_face.normal.samedirection?(original_normal) ? -top_rail_depth_su : top_rail_depth_su
          rail_face.pushpull(pushpull_dist) rescue nil
          created_rails << rail_group.to_component
        else
          rail_group.erase!
        end
      end
    end

    if @@enable_bottom_rail
      bottom_edges = classified_edges.select { |e| 
        (e[:local_p1].y - actual_min_y).abs < 0.5 || (e[:local_p2].y - actual_min_y).abs < 0.5
      }
      puts "[RAILS] Bottom rail: found #{bottom_edges.length} edges at y=#{actual_min_y.round(2)}"
      
      continuous_segments = []
      bottom_edges.sort_by { |e| [e[:local_p1].x, e[:local_p2].x].min }.each do |edge_data|
        if continuous_segments.empty?
          continuous_segments << [edge_data]
        else
          last_segment = continuous_segments.last
          last_edge = last_segment.last
          gap = [edge_data[:local_p1].x, edge_data[:local_p2].x].min - [last_edge[:local_p1].x, last_edge[:local_p2].x].max
          
          if gap < 1.0
            last_segment << edge_data
          else
            continuous_segments << [edge_data]
          end
        end
      end
      
      continuous_segments.each do |segment|
        min_x = segment.map { |e| [e[:local_p1].x, e[:local_p2].x].min }.min
        max_x = segment.map { |e| [e[:local_p1].x, e[:local_p2].x].max }.max
        
        left_has_perp = find_perpendicular_face_at_corner(face_data, all_faces_data,
          {local_p1: Geom::Point3d.new(min_x, actual_min_y, 0), local_p2: Geom::Point3d.new(min_x, actual_min_y, 0)}, face_transform)
        right_has_perp = find_perpendicular_face_at_corner(face_data, all_faces_data,
          {local_p1: Geom::Point3d.new(max_x, actual_min_y, 0), local_p2: Geom::Point3d.new(max_x, actual_min_y, 0)}, face_transform)
        
        rail_end_y = actual_min_y - joint_width_su
        rail_start_y = rail_end_y - bottom_rail_thickness_su
        
        p1 = Geom::Point3d.new(min_x, rail_start_y, 0)
        p2 = Geom::Point3d.new(max_x, rail_start_y, 0)
        p3 = Geom::Point3d.new(max_x, rail_end_y, 0)
        p4 = Geom::Point3d.new(min_x, rail_end_y, 0)
        
        if left_has_perp
          p1 = Geom::Point3d.new(min_x - bottom_rail_thickness_su, rail_start_y, 0)
          p4 = Geom::Point3d.new(min_x - bottom_rail_thickness_su, rail_end_y, 0)
        end
        if right_has_perp
          p2 = Geom::Point3d.new(max_x + bottom_rail_thickness_su, rail_start_y, 0)
          p3 = Geom::Point3d.new(max_x + bottom_rail_thickness_su, rail_end_y, 0)
        end
        
        rail_group = main_group.entities.add_group
        rail_face = rail_group.entities.add_face([p1, p2, p3, p4].map { |pt| pt.transform(face_transform) }) rescue nil
        if rail_face
          rail_face.material = rail_material
          rail_face.back_material = rail_material
          pushpull_dist = rail_face.normal.samedirection?(original_normal) ? -bottom_rail_depth_su : bottom_rail_depth_su
          rail_face.pushpull(pushpull_dist) rescue nil
          created_rails << rail_group.to_component
        else
          rail_group.erase!
        end
      end
    end

    if @@enable_left_rail
      # Left rail: Find VERTICAL edges (top/bottom orientation) at minimum X
      # These are edges that run up-down at the left of the layout
      left_edges = classified_edges.select { |e| 
        # Edge must be at the left X position
        (e[:local_p1].x - actual_min_x).abs < 0.5 || (e[:local_p2].x - actual_min_x).abs < 0.5
      }
      puts "[RAILS] Left rail: found #{left_edges.length} edges at x=#{actual_min_x.round(2)}"
      left_edges.each do |edge_data|
        rail_end_x = actual_min_x - joint_width_su
        rail_pts = create_mitered_rail_points(edge_data, rail_end_x - left_rail_thickness_su, rail_end_x, left_rail_thickness_su, local_bounds, false)
        
        rail_group = main_group.entities.add_group
        rail_face = rail_group.entities.add_face(rail_pts.map { |pt| pt.transform(face_transform) }) rescue nil
        if rail_face
          rail_face.material = rail_material
          rail_face.back_material = rail_material
          pushpull_dist = rail_face.normal.samedirection?(original_normal) ? -left_rail_depth_su : left_rail_depth_su
          rail_face.pushpull(pushpull_dist) rescue nil
          created_rails << rail_group.to_component
        else
          rail_group.erase!
        end
      end
    end

    if @@enable_right_rail
      # Right rail: Find VERTICAL edges (top/bottom orientation) at maximum X
      # These are edges that run up-down at the right of the layout
      right_edges = classified_edges.select { |e| 
        # Edge must be at the right X position
        (e[:local_p1].x - actual_max_x).abs < 0.5 || (e[:local_p2].x - actual_max_x).abs < 0.5
      }
      puts "[RAILS] Right rail: found #{right_edges.length} edges at x=#{actual_max_x.round(2)}"
      right_edges.each do |edge_data|
        rail_start_x = actual_max_x + joint_width_su
        rail_pts = create_mitered_rail_points(edge_data, rail_start_x, rail_start_x + right_rail_thickness_su, right_rail_thickness_su, local_bounds, false)
        
        rail_group = main_group.entities.add_group
        rail_face = rail_group.entities.add_face(rail_pts.map { |pt| pt.transform(face_transform) }) rescue nil
        if rail_face
          rail_face.material = rail_material
          rail_face.back_material = rail_material
          pushpull_dist = rail_face.normal.samedirection?(original_normal) ? -right_rail_depth_su : right_rail_depth_su
          rail_face.pushpull(pushpull_dist) rescue nil
          created_rails << rail_group.to_component
        else
          rail_group.erase!
        end
      end
    end

    created_rails.empty? ? nil : created_rails
  end

end