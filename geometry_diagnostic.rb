# PARAMETRIX Geometry Diagnostic Tool
# Run this to analyze selected faces and identify potential issues

module PARAMETRIX
  
  def self.diagnose_selected_geometry
    model = Sketchup.active_model
    selection = model.selection
    
    if selection.empty?
      UI.messagebox("Please select one or more faces to diagnose.")
      return
    end
    
    puts "\n" + "="*80
    puts "[PARAMETRIX DIAGNOSTIC] Starting geometry analysis..."
    puts "="*80
    
    faces_data = analyze_multi_face_selection(selection)
    
    if faces_data.empty?
      puts "[DIAGNOSTIC] ❌ No valid faces found in selection"
      UI.messagebox("No valid faces found in selection. Please select faces directly or groups/components containing faces.")
      return
    end
    
    puts "[DIAGNOSTIC] Found #{faces_data.length} face(s) to analyze\n"
    
    total_issues = 0
    critical_issues = 0
    warnings = 0
    
    faces_data.each_with_index do |face_data, index|
      face = face_data[:face]
      face_matrix = face_data[:matrix]
      
      puts "\n" + "-"*80
      puts "[DIAGNOSTIC] Face #{index + 1} of #{faces_data.length}"
      puts "-"*80
      
      # Basic properties
      vertex_count = face.outer_loop.vertices.length
      loop_count = face.loops.length
      edge_count = face.outer_loop.edges.length
      area = face.area
      
      # Check if truly rectangular (4 vertices with 90-degree angles)
      is_rectangular = false
      if vertex_count == 4
        edges = face.outer_loop.edges
        angles = []
        edges.each_with_index do |edge, i|
          next_edge = edges[(i + 1) % edges.length]
          angle = edge.line[1].angle_between(next_edge.line[1])
          angles << (angle * 180.0 / Math::PI).round(1)
        end
        is_rectangular = angles.all? { |a| (a - 90.0).abs < 1.0 || (a - 270.0).abs < 1.0 }
      end
      
      puts "  Basic Properties:"
      puts "    • Vertices: #{vertex_count}"
      puts "    • Edges: #{edge_count}"
      puts "    • Loops: #{loop_count} (#{loop_count - 1} hole(s))"
      puts "    • Area: #{area.round(2)} sq units"
      puts "    • Type: #{is_rectangular ? 'Rectangular' : (vertex_count == 4 ? 'Quadrilateral (non-rectangular)' : 'Complex')}"
      
      # Check for issues
      face_issues = []
      face_warnings = []
      
      # Check 1: Through-holes
      if loop_count > 2
        face_issues << "Multiple holes detected (#{loop_count - 1} holes) - May cause vector calculation failures"
        critical_issues += 1
      elsif loop_count > 1
        face_warnings << "Single hole detected - Should work but may have edge cases"
        warnings += 1
      end
      
      # Check 2: Degenerate edges
      degenerate_edges = []
      face.outer_loop.edges.each_with_index do |edge, edge_idx|
        edge_length = edge.length
        if edge_length < 0.001
          degenerate_edges << edge_idx
        end
      end
      
      if degenerate_edges.length > 0
        face_issues << "#{degenerate_edges.length} degenerate edge(s) found (zero-length) - Will cause vector normalization errors"
        critical_issues += 1
      end
      
      # Check 3: Face normal
      face_normal = face.normal
      if face_matrix && face_matrix != Geom::Transformation.new
        face_normal = face_normal.transform(face_matrix)
      end
      
      if face_normal.length < 0.001
        face_issues << "Invalid face normal (zero-length) - Critical error"
        critical_issues += 1
      end
      
      # Check 4: Area threshold
      unit_conversion = get_effective_unit_conversion
      min_area = (100.0 * unit_conversion) ** 2
      
      if area < min_area
        face_issues << "Face area too small (#{area.round(2)} < #{min_area.round(2)}) - Below minimum threshold"
        critical_issues += 1
      end
      
      # Check 5: Edge validity for vector calculation
      valid_edges = 0
      face.outer_loop.edges.each do |edge|
        edge_vec = edge.end.position - edge.start.position
        if face_matrix && face_matrix != Geom::Transformation.new
          edge_vec = edge_vec.transform(face_matrix)
        end
        valid_edges += 1 if edge_vec.length > 0.001
      end
      
      if valid_edges == 0
        face_issues << "No valid edges for orientation calculation - Critical error"
        critical_issues += 1
      elsif valid_edges < edge_count / 2
        face_warnings << "Many invalid edges (#{edge_count - valid_edges}/#{edge_count}) - May cause issues"
        warnings += 1
      end
      
      # Check 6: Planarity
      vertices = face.outer_loop.vertices.map { |v| v.position }
      if vertices.length >= 3
        plane = Geom.fit_plane_to_points(vertices)
        if plane
          max_deviation = 0.0
          vertices.each do |pt|
            deviation = pt.distance_to_plane(plane)
            max_deviation = [max_deviation, deviation].max
          end
          
          if max_deviation > 1.0
            face_warnings << "Face may not be perfectly planar (max deviation: #{max_deviation.round(3)})"
            warnings += 1
          end
        end
      end
      
      # Report issues
      if face_issues.empty? && face_warnings.empty?
        puts "  Status: ✓ No issues detected"
      else
        if !face_issues.empty?
          puts "  Critical Issues (#{face_issues.length}):"
          face_issues.each { |issue| puts "    ❌ #{issue}" }
          total_issues += face_issues.length
        end
        
        if !face_warnings.empty?
          puts "  Warnings (#{face_warnings.length}):"
          face_warnings.each { |warning| puts "    ⚠ #{warning}" }
          total_issues += face_warnings.length
        end
      end
    end
    
    # Summary
    puts "\n" + "="*80
    puts "[DIAGNOSTIC] Analysis Complete"
    puts "="*80
    puts "  Total Faces: #{faces_data.length}"
    puts "  Critical Issues: #{critical_issues}"
    puts "  Warnings: #{warnings}"
    puts "  Total Issues: #{total_issues}"
    
    if critical_issues > 0
      puts "\n  ❌ RECOMMENDATION: Fix critical issues before attempting layout generation"
      puts "     Common fixes:"
      puts "     • Remove through-holes or create separate faces"
      puts "     • Clean up degenerate edges using SketchUp's cleanup tools"
      puts "     • Ensure faces meet minimum area requirements"
      puts "     • Select faces individually instead of multiple volumes"
    elsif warnings > 0
      puts "\n  ⚠ RECOMMENDATION: Layout may work but could have issues"
      puts "     Consider simplifying geometry for best results"
    else
      puts "\n  ✓ RECOMMENDATION: Geometry looks good for layout generation"
    end
    
    puts "="*80 + "\n"
    
    # Show dialog with summary
    message = "Geometry Diagnostic Results:\n\n"
    message += "Faces Analyzed: #{faces_data.length}\n"
    message += "Critical Issues: #{critical_issues}\n"
    message += "Warnings: #{warnings}\n\n"
    
    if critical_issues > 0
      message += "❌ Critical issues detected. Check Ruby Console for details.\n\n"
      message += "Common fixes:\n"
      message += "• Remove through-holes\n"
      message += "• Clean degenerate edges\n"
      message += "• Select faces individually"
    elsif warnings > 0
      message += "⚠ Warnings detected. Layout may work but could have issues.\n"
      message += "Check Ruby Console for details."
    else
      message += "✓ No issues detected. Geometry is ready for layout generation."
    end
    
    UI.messagebox(message)
  end
  
end
