# PARAMETRIX Layout Engine
# Contains the main layout generation logic and unified layout processing

module PARAMETRIX

    def self.create_unified_layout_for_face(face_transform_data, main_group, materials, unit_conversion, length_values, height_values, face_index, total_faces, cavity_distance_su, global_start_x, global_start_y, elements_x, elements_y, joint_length_su, joint_width_su, avg_length_su, avg_height_su, thickness_su, single_row_mode, layout_start_direction_for_single_row, is_preview = false, start_row_height_index = 1)
    
    face_data = face_transform_data[:face_data]
    face = face_data[:face]
    face_matrix = face_data[:matrix]
    face_transform = face_transform_data[:transform]
    local_bounds = face_transform_data[:local_bounds]
    corner_type = face_transform_data[:corner_type]
    original_normal = face_transform_data[:original_normal]

    vertex_count = face.outer_loop.vertices.length
    face_type = vertex_count == 4 ? "RECTANGULAR" : "COMPLEX (#{vertex_count} sides)"
    

    face_group = main_group.entities.add_group
    face_group.name = "Face_#{face_index + 1}_Unified_#{corner_type.capitalize}"

    element_count = 0
    trimmed_count = 0
    piece_index = 0

    # Use global synchronized seed for all faces (stable behavior)
    if @@synchronize_patterns
      srand(12345)
    end

    pos_y = global_start_y 
    current_height_su = avg_height_su # Default, will be updated
    

    stone_min_y_for_rails = Float::INFINITY
    stone_max_y_for_rails = -Float::INFINITY
    top_row_joint_positions = []
    bottom_row_joint_positions = []
    
    # Initialize rail bounds based on layout bounds
    initial_stone_min_y = local_bounds.min.y
    initial_stone_max_y = local_bounds.max.y

    # Override vertical positioning for single-row mode
    if single_row_mode
      current_height_su = height_values[0] * unit_conversion # User-specified height
      
      bottom_rail_thickness_su = @@enable_bottom_rail ? @@bottom_rail_thickness * unit_conversion : 0.0
      top_rail_thickness_su = @@enable_top_rail ? @@top_rail_thickness * unit_conversion : 0.0
      
      # PER-FACE ALIGNMENT: Use local bounds for each face independently
      # This ensures single-row layouts align to each face's own coordinate system
      effective_min_y = local_bounds.min.y + bottom_rail_thickness_su + joint_width_su
      effective_max_y = local_bounds.max.y - top_rail_thickness_su - joint_width_su
      
      available_vertical_space = effective_max_y - effective_min_y

      # Ensure the custom height doesn't exceed available space
      if current_height_su > available_vertical_space
        current_height_su = available_vertical_space
      end

      # Determine the starting Y position (bottom of the row) based on layout_start_direction
      # IMPORTANT: For single-row, always use per-face alignment (not global)
      case layout_start_direction_for_single_row
      when "bottom_left", "bottom", "bottom_right"
        pos_y = effective_min_y

      when "top_left", "top", "top_right"
        pos_y = effective_max_y - current_height_su

      when "left", "right", "center"
        pos_y = effective_min_y + (available_vertical_space - current_height_su) / 2.0

      else # fallback to center
        pos_y = effective_min_y + (available_vertical_space - current_height_su) / 2.0

      end
      
      # Store the actual stone bounds for rail placement - FIXED: Use actual stone positions
      stone_min_y_for_rails = pos_y
      stone_max_y_for_rails = pos_y + current_height_su
      
      puts "[PARAMETRIX] Face #{face_index + 1}: Single-row Y-position = #{pos_y.round(2)} (per-face alignment)"


    else
      # MULTI-ROW MODE: Uses global synchronization across faces
      # height_index should start at 0 because height_values is already rotated
      # The rotation happens in create_multi_face_unified_layout via get_height_values_with_start_index
      height_index = 0
      # Initialize with local bounds - will be updated as stones are placed
      stone_min_y_for_rails = initial_stone_max_y  # Start high, will be lowered
      stone_max_y_for_rails = initial_stone_min_y  # Start low, will be raised
    end



    # Generate layout using GLOBAL start position (no limits)
    for row in 0...elements_y

      unless single_row_mode # Only apply height pattern logic for multi-row mode
        if height_values.length > 1 && @@randomize_heights
          # Use dedicated height seed for synchronization with global row position
          if @@synchronize_patterns
            # Calculate global row index to ensure same height pattern across faces
            global_row = ((pos_y - global_start_y) / (avg_height_su + joint_width_su)).round
            srand(@current_height_seed + global_row)
          end
          current_height = height_values[rand(height_values.length)]
        elsif height_values.length > 1
          # Use global row position for consistent height pattern
          if @@synchronize_patterns
            global_row = ((pos_y - global_start_y) / (avg_height_su + joint_width_su)).round
            pattern_index = (height_index + global_row) % height_values.length
          else
            pattern_index = height_index % height_values.length
          end
          current_height = height_values[pattern_index]
          if row == 0
            puts "[PARAMETRIX] Row 0 - Using height_index=#{height_index}, pattern_index=#{pattern_index}, height_values[#{pattern_index}]=#{current_height}, Full pattern=[#{height_values.join(', ')}]"
            puts "BOTTOM_ROW_HEIGHT: #{current_height}"
          end
          height_index += 1
        else
          current_height = height_values[0]
        end
        current_height_su = current_height * unit_conversion
      end

      # Calculate row offset using global position for synchronization
      row_offset = case @@pattern_type
      when "running_bond"
        (row % 2) * (avg_length_su + joint_length_su) * 0.5
      else
        0.0
      end

      row_start_x = global_start_x + row_offset
      pos_x = row_start_x
      length_index = 0

      # Pre-calculate row pieces with gap filling
      row_pieces = []
      temp_pos_x = pos_x
      temp_length_index = length_index
      
      # Generate initial pieces for this row
      for col in 0...elements_x
        if length_values.length > 1 && (single_row_mode ? @@single_row_randomize_lengths : @@randomize_lengths)
          current_length = length_values[rand(length_values.length)]
        elsif length_values.length > 1
          current_length = length_values[temp_length_index % length_values.length]
          temp_length_index += 1
        else
          current_length = length_values[0]
        end
        current_length_su = current_length * unit_conversion
        
        element_right = temp_pos_x + current_length_su
        intersect_left = [temp_pos_x, local_bounds.min.x].max
        intersect_right = [element_right, local_bounds.max.x].min
        
        if intersect_left < intersect_right
          trimmed_width = intersect_right - intersect_left
          row_pieces << {
            pos_x: temp_pos_x,
            length_su: current_length_su,
            trimmed_width: trimmed_width,
            intersect_left: intersect_left,
            intersect_right: intersect_right
          }
        end
        
        temp_pos_x += current_length_su + joint_length_su
        break if temp_pos_x >= local_bounds.max.x + avg_length_su
      end
      
      # Apply minimum piece constraint with gap filling
      min_piece_su = @@enable_min_piece_length ? @@min_piece_length * unit_conversion : 0.0
      if @@enable_min_piece_length && min_piece_su > 0.001
        filtered_pieces = []
        i = 0
        while i < row_pieces.length
          piece = row_pieces[i]
          
          if piece[:trimmed_width] < min_piece_su
            # Small piece - extend adjacent piece to fill gap
            gap_width = piece[:trimmed_width] + joint_length_su
            
            if i > 0 && filtered_pieces.length > 0
              # Extend previous piece
              prev_piece = filtered_pieces.last
              prev_piece[:length_su] += gap_width
              prev_piece[:intersect_right] += gap_width
            elsif i < row_pieces.length - 1
              # Extend next piece
              next_piece = row_pieces[i + 1]
              next_piece[:pos_x] -= gap_width
              next_piece[:length_su] += gap_width
              next_piece[:intersect_left] -= gap_width
            end
          else
            filtered_pieces << piece
          end
          i += 1
        end
        row_pieces = filtered_pieces
      end
      
      # Create actual pieces from processed row data
      row_pieces.each do |piece_data|
        element_top = pos_y + current_height_su
        intersect_bottom = [pos_y, local_bounds.min.y].max
        intersect_top = [element_top, local_bounds.max.y].min
        
        if piece_data[:intersect_left] < piece_data[:intersect_right] && intersect_bottom < intersect_top
          trimmed_width = piece_data[:intersect_right] - piece_data[:intersect_left]
          trimmed_height = intersect_top - intersect_bottom

          if trimmed_width > 0.001 && trimmed_height > 0.001
            local_points = [
              Geom::Point3d.new(piece_data[:intersect_left], intersect_bottom, 0),
              Geom::Point3d.new(piece_data[:intersect_right], intersect_bottom, 0),
              Geom::Point3d.new(piece_data[:intersect_right], intersect_top, 0),
              Geom::Point3d.new(piece_data[:intersect_left], intersect_top, 0)
            ]

            world_points = local_points.map { |pt| pt.transform(face_transform) }

            # Determine if random thickness should be used
            use_random_thickness = single_row_mode ? @@single_row_randomize_thickness : @@randomize_thickness
            
            if create_piece_with_ghosting(face_group, world_points, materials, thickness_su, original_normal, piece_index, elements_x * elements_y, is_preview, face, face_matrix, use_random_thickness, unit_conversion, single_row_mode)
              element_count += 1
              piece_index += 1

              if intersect_top >= stone_max_y_for_rails
                if (intersect_top - stone_max_y_for_rails).abs > 0.001
                  top_row_joint_positions = [] # new top row
                end
                stone_max_y_for_rails = intersect_top
                top_row_joint_positions << { start: piece_data[:intersect_left], end: piece_data[:intersect_right] }
              end

              if intersect_bottom <= stone_min_y_for_rails
                if (intersect_bottom - stone_min_y_for_rails).abs > 0.001
                  bottom_row_joint_positions = [] # new bottom row
                end
                stone_min_y_for_rails = intersect_bottom
                bottom_row_joint_positions << { start: piece_data[:intersect_left], end: piece_data[:intersect_right] }
              end

              if trimmed_width < piece_data[:length_su] - 0.001 || trimmed_height < current_height_su - 0.001
                trimmed_count += 1
              end
            end
          end
        end

      end
      # Only advance pos_y if not in single_row_mode (as it's fixed for single row)
      # In multi-row mode, rows always build upward from the starting Y position
      unless single_row_mode
        pos_y += current_height_su + joint_width_su
      end
    end
    
    if !is_preview
      # OOB METHOD: Trim 2D faces FIRST
      trimmed_result = PARAMETRIX_TRIMMING_V4.boolean2d_exact(face_group, face, face_matrix)
      face_group = trimmed_result if trimmed_result

      # THEN extrude trimmed 2D faces to 3D
      if face_group.is_a?(Sketchup::ComponentInstance)
        extrude_entities = face_group.definition.entities
      else
        extrude_entities = face_group.entities
      end
      
      # Recalculate rail positions AND bounds from TRIMMED faces
      stone_min_y_for_rails = Float::INFINITY
      stone_max_y_for_rails = -Float::INFINITY
      stone_min_x = Float::INFINITY
      stone_max_x = -Float::INFINITY
      top_row_joint_positions = []
      bottom_row_joint_positions = []
      
      extrude_entities.grep(Sketchup::Face).each do |f|
        # Update rail bounds from trimmed geometry
        f.vertices.each do |v|
          y = v.position.y
          x = v.position.x
          stone_min_y_for_rails = [stone_min_y_for_rails, y].min
          stone_max_y_for_rails = [stone_max_y_for_rails, y].max
          stone_min_x = [stone_min_x, x].min
          stone_max_x = [stone_max_x, x].max
        end
        
        # Track joint positions
        bounds = f.bounds
        if (bounds.max.y - stone_max_y_for_rails).abs < 0.01
          top_row_joint_positions << { start: bounds.min.x, end: bounds.max.x }
        end
        if (bounds.min.y - stone_min_y_for_rails).abs < 0.01
          bottom_row_joint_positions << { start: bounds.min.x, end: bounds.max.x }
        end
      end
      
      # Extrude all faces
      extrude_entities.grep(Sketchup::Face).each do |f|
        thickness = f.get_attribute('PARAMETRIX_DATA', 'thickness')
        original_normal = f.get_attribute('PARAMETRIX_DATA', 'original_normal')
        
        if thickness && thickness > 0.001 && original_normal
          layout_normal = f.normal
          pushpull_distance = layout_normal.samedirection?(original_normal) ? -thickness : thickness
          f.pushpull(pushpull_distance)
        end
      end
      puts "[PARAMETRIX] 3D extrusion completed. Rails: Y[#{stone_min_y_for_rails.round(2)}..#{stone_max_y_for_rails.round(2)}], X[#{stone_min_x.round(2)}..#{stone_max_x.round(2)}]"
      
      # Update local_bounds in OUTER scope for rails
      local_bounds = Geom::BoundingBox.new
      local_bounds.add(Geom::Point3d.new(stone_min_x, stone_min_y_for_rails, 0))
      local_bounds.add(Geom::Point3d.new(stone_max_x, stone_max_y_for_rails, 0))
    else
      # Preview: extrude immediately for visualization
      face_group.entities.grep(Sketchup::Face).each do |f|
        next unless f.valid?
        thickness = f.get_attribute('PARAMETRIX_DATA', 'thickness')
        original_normal = f.get_attribute('PARAMETRIX_DATA', 'original_normal')
        
        if thickness && thickness > 0.001 && original_normal
          begin
            layout_normal = f.normal
            pushpull_distance = layout_normal.samedirection?(original_normal) ? -thickness : thickness
            f.pushpull(pushpull_distance)
          rescue
          end
        end
      end
    end
    
    # Debug: Check what bounds are being passed to rails
    puts "[PARAMETRIX] Rails will use bounds: X[#{local_bounds.min.x.round(2)}..#{local_bounds.max.x.round(2)}], Y[#{local_bounds.min.y.round(2)}..#{local_bounds.max.y.round(2)}]"
    
    # Create rails in both preview and final mode
    # TODO: Rails should follow face edges, not just be rectangles
    # For now, skip rails to avoid incorrect placement
    # rail_material = materials.length > 1 ? materials[1] : materials[0]
    # top_row_joint_positions.sort_by! { |p| p[:start] }
    # bottom_row_joint_positions.sort_by! { |p| p[:start] }
    # rails_group = create_rails_for_face(face_data, main_group, rail_material, unit_conversion, face_index, cavity_distance_su, [face_data], local_bounds, face_transform, original_normal, single_row_mode, stone_min_y_for_rails, stone_max_y_for_rails, joint_width_su, top_row_joint_positions, bottom_row_joint_positions)
    rails_group = nil

    unit_name = get_effective_unit


    return { elements: element_count, trimmed: trimmed_count, group: face_group, rails: rails_group }
  end

  def self.create_multi_face_unified_layout(multi_face_position, redo_mode = 0, options = {})
    return 0 unless multi_face_position && multi_face_position.valid?

    is_preview = options[:preview] || false
    
    begin
      model = Sketchup.active_model
      active_entities, context_name = get_proper_active_context

      if is_preview
        puts "[PARAMETRIX] Creating preview with UNIFIED LAYOUT..."
        remove_preview
      else
        model.start_operation("PARAMETRIX Layout", true)
        puts "[PARAMETRIX] Creating UNIFIED layout..."
        remove_preview
      end

      unit_conversion = get_effective_unit_conversion
      unit_name = get_effective_unit
      
      # Conditional parameter selection based on @@single_row_mode
      if @@single_row_mode
        length_values = parse_multi_values(@@single_row_length.to_s, @@single_row_randomize_lengths)
        
        height_values = parse_multi_values(@@single_row_height.to_s, false) # Height is always a single value for single row
        thickness_su = @@single_row_thickness * unit_conversion
        joint_length_su = @@single_row_joint_length * unit_conversion
        joint_width_su = @@single_row_joint_width * unit_conversion
        cavity_distance_su = @@single_row_cavity_distance * unit_conversion
        pattern_type_for_face = @@single_row_pattern_type
        randomize_lengths_for_face = @@single_row_randomize_lengths
        randomize_heights_for_face = false # Always false for single row
        layout_start_direction_for_face = @@layout_start_direction # Still use global layout start for vertical alignment of single row
        start_row_height_index_for_face = 1 # Not relevant, but set to 1
        puts "[PARAMETRIX] Single-Row Layout Mode ACTIVE. Using dedicated parameters."
      else
        length_values = parse_multi_values(@@length.to_s, @@randomize_lengths)
        
        height_values = parse_multi_values(@@height.to_s, @@randomize_heights)
        thickness_su = @@thickness * unit_conversion
        joint_length_su = @@joint_length * unit_conversion
        joint_width_su = @@joint_width * unit_conversion
        cavity_distance_su = @@cavity_distance * unit_conversion
        pattern_type_for_face = @@pattern_type
        randomize_lengths_for_face = @@randomize_lengths
        randomize_heights_for_face = @@randomize_heights
        layout_start_direction_for_face = @@layout_start_direction
        start_row_height_index_for_face = @@start_row_height_index
        puts "[PARAMETRIX] Multi-Row Layout Mode ACTIVE. Using general parameters."
      end

      # Default values if parsing results in empty arrays
      if length_values.empty?
        case unit_name
        when "mm" then length_values = [1000.0]
        when "cm" then length_values = [100.0]
        when "m" then length_values = [1.0]
        else length_values = [40.0]
        end
      end

      if height_values.empty?
        case unit_name
        when "mm" then height_values = [620.0]
        when "cm" then height_values = [62.0]
        when "m" then height_values = [0.62]
        else height_values = [24.4]
        end
      end
      

      puts "[PARAMETRIX] Original height values: [#{height_values.join(', ')}]"
      puts "[PARAMETRIX] Height index requested: #{start_row_height_index_for_face}"
      height_values = get_height_values_with_start_index(height_values, start_row_height_index_for_face)
      puts "[PARAMETRIX] Final height pattern: [#{height_values.join(', ')}]"
      
      # Set global randomization seeds for synchronization
      if @@synchronize_patterns
        # Use separate seeds for length and height randomization
        @global_length_seed = 12345
        @global_height_seed = 54321
      end

      puts "[PARAMETRIX] ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■  ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ "
      puts "[PARAMETRIX] 🌍 MULTI-FACE UNIFIED LAYOUT PROCESSING"
      puts "[PARAMETRIX] ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ "
      puts "[PARAMETRIX] Faces: #{multi_face_position.face_count}"
      puts "[PARAMETRIX] Mode: UNIFIED (Global top/bottom synchronization)"
      if @@single_row_mode
        puts "[PARAMETRIX]   └─ Single-Row Layout Mode ACTIVE"
      end

      materials = create_materials(@@color_name, @@rail_color_name)

      if is_preview
        main_group = active_entities.add_group
        main_group.name = "PARAMETRIX Preview"
        @@preview_group = main_group
      else
        main_group = active_entities.add_group
        main_group.name = "PARAMETRIX Layout"
      end

      # Collect all faces data
      all_faces_data = []
      (0...multi_face_position.face_count).each do |face_index|
        all_faces_data << multi_face_position.get_face_data(face_index)
      end

      # Calculate global unified bounds with error handling
      begin
        unified_data = calculate_global_unified_bounds(all_faces_data, cavity_distance_su)
        global_bounds = unified_data[:global_bounds]
        reference_transform = unified_data[:reference_transform]
        face_transforms = unified_data[:face_transforms]
      rescue => bounds_error
        puts "[PARAMETRIX] ERROR: Failed to calculate unified bounds"
        puts "[PARAMETRIX] Error: #{bounds_error.message}"
        puts "[PARAMETRIX] This often occurs with:"
        puts "[PARAMETRIX]   - Faces with through-holes"
        puts "[PARAMETRIX]   - Degenerate geometry (zero-length edges)"
        puts "[PARAMETRIX]   - Multiple disconnected volumes"
        puts "[PARAMETRIX] Suggestion: Try selecting faces individually or simplify geometry"
        raise bounds_error
      end

      avg_length = length_values.sum / length_values.length
      avg_height = height_values.sum / height_values.length 
      avg_length_su = avg_length * unit_conversion
      avg_height_su = avg_height * unit_conversion

      # Calculate unified start position based on global bounds
      global_start_x, global_start_y, elements_x, elements_y = calculate_unified_start_position(
        global_bounds, avg_length_su, avg_height_su, joint_length_su, joint_width_su, @@single_row_mode
      )

      # No artificial limits - let layout cover the full area
      # elements_x and elements_y calculated based on actual face dimensions

      total_elements = 0
      total_trimmed = 0
      face_results = []

      # Process each face individually for complete coverage
      face_transforms.each_with_index do |ft, face_index|
        # Calculate individual layout parameters for THIS face
        face_local_bounds = ft[:local_bounds]
        
        face_elements_x = ((face_local_bounds.width + joint_length_su) / (avg_length_su + joint_length_su)).ceil + 4
        
        face_elements_y = @@single_row_mode ? 1 : ((face_local_bounds.height + joint_width_su) / (avg_height_su + joint_width_su)).ceil + 4
        
        # Calculate face-specific start position based on layout direction (stable)
        case layout_start_direction_for_face
        when "top_left"
          face_start_x = face_local_bounds.min.x - avg_length_su
          face_start_y = face_local_bounds.max.y - face_elements_y * avg_height_su
        when "top"
          face_start_x = face_local_bounds.min.x + (face_local_bounds.width - face_elements_x * avg_length_su) / 2.0
          face_start_y = face_local_bounds.max.y - face_elements_y * avg_height_su
        when "top_right"
          face_start_x = face_local_bounds.max.x - avg_length_su
          face_start_y = face_local_bounds.max.y - face_elements_y * avg_height_su
        when "left"
          face_start_x = face_local_bounds.min.x - avg_length_su
          face_start_y = face_local_bounds.min.y + (face_local_bounds.height - face_elements_y * avg_height_su) / 2.0
        when "right"
          face_start_x = face_local_bounds.max.x - avg_length_su
          face_start_y = face_local_bounds.min.y + (face_local_bounds.height - face_elements_y * avg_height_su) / 2.0
        when "bottom_left"
          face_start_x = face_local_bounds.min.x - avg_length_su
          face_start_y = face_local_bounds.min.y - avg_height_su
        when "bottom"
          face_start_x = face_local_bounds.min.x + (face_local_bounds.width - face_elements_x * avg_length_su) / 2.0
          face_start_y = face_local_bounds.min.y - avg_height_su
        when "bottom_right"
          face_start_x = face_local_bounds.max.x - avg_length_su
          face_start_y = face_local_bounds.min.y - avg_height_su
        else # center
          face_start_x = face_local_bounds.min.x + (face_local_bounds.width - face_elements_x * avg_length_su) / 2.0
          face_start_y = face_local_bounds.min.y + (face_local_bounds.height - face_elements_y * avg_height_su) / 2.0
        end

        if @@single_row_mode
          face_start_y = face_local_bounds.min.y
        end
        
        result = create_unified_layout_for_face(
          ft, main_group, materials, unit_conversion, 
          length_values, height_values, face_index, multi_face_position.face_count, 
          cavity_distance_su, face_start_x, face_start_y, face_elements_x, face_elements_y,
          joint_length_su, joint_width_su, avg_length_su, avg_height_su, thickness_su,
          @@single_row_mode, layout_start_direction_for_face, is_preview
        )

        face_results << result
        total_elements += result[:elements]
        total_trimmed += result[:trimmed]
      end

      if !is_preview
        model.commit_operation
      end
      
      puts "TEST: Direction=#{layout_start_direction_for_face}, HeightIndex=#{start_row_height_index_for_face} → Elements=#{total_elements}, BottomRowHeight=#{height_values[0]}"

      return 1

    rescue => e
      if !is_preview
        model.abort_operation if model
      end
      return 0
    end
  end

end