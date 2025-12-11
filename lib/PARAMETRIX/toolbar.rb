if !defined?(@parametrics_toolbar_loaded) || @parametrics_toolbar_loaded.nil?
  begin
    if defined?(PARAMETRIX) && defined?(PARAMETRIX.method(:start_layout_process))
      toolbar = UI::Toolbar.new "PARAMETRIX"
      
      cmd = UI::Command.new("PARAMETRIX Layout Generator") {
        PARAMETRIX.start_layout_process
      }
      
      cmd.menu_text = "PARAMETRIX Layout Generator"
      cmd.tooltip = "Generate parametric cladding layouts with advanced trimming"
      cmd.status_bar_text = "Generate PARAMETRIX cladding layout"
      
      # Use relative paths for icons to make the extension portable
      extension_dir = File.dirname(File.dirname(__FILE__))
      small_icon_path = File.join(extension_dir, "..", "TB_V005_UNIFIED_16.png")
      large_icon_path = File.join(extension_dir, "..", "TB_V005_UNIFIED_24.png")
      
      cmd.small_icon = small_icon_path if File.exist?(small_icon_path)
      cmd.large_icon = large_icon_path if File.exist?(large_icon_path)
      
      toolbar.add_item cmd
      toolbar.show
      
      # Create main menu structure
      menu = UI.menu("Extensions")
      parametrix_menu = menu.add_submenu("PARAMETRIX")
      parametrix_menu.add_item(cmd)
      parametrix_menu.add_separator
      
      # Create Help submenu
      help_menu = parametrix_menu.add_submenu("Help")
      
      # Parametric Guide
      help_cmd = UI::Command.new("Parametric Guide") {
        doc_path = File.join(File.dirname(File.dirname(File.dirname(__FILE__))), "PARAMETRIX_Documentation.html")
        if File.exist?(doc_path)
          UI.openURL("file:///#{doc_path.gsub('\\', '/')}")
        else
          UI.messagebox("Documentation file not found at: #{doc_path}")
        end
      }
      help_cmd.menu_text = "Parametric Guide"
      help_menu.add_item(help_cmd)
      
      # License Information
      license_cmd = UI::Command.new("License Information") {
        PARAMETRIX.show_license_info
      }
      license_cmd.menu_text = "License Information"
      help_menu.add_item(license_cmd)
      
      # Check for Updates
      update_cmd = UI::Command.new("Check for Updates") {
        PARAMETRIX.check_for_updates
      }
      update_cmd.menu_text = "Check for Updates"
      help_menu.add_item(update_cmd)
      
      help_menu.add_separator
      
      # Contact Support
      support_cmd = UI::Command.new("Contact Support") {
        PARAMETRIX.contact_support
      }
      support_cmd.menu_text = "Contact Support"
      help_menu.add_item(support_cmd)
      
    else
      puts "PARAMETRIX module not loaded, skipping toolbar creation"
    end
  rescue => e
    puts "[PARAMETRIX] Error creating toolbar: #{e.message}"
    puts e.backtrace.first(5).join("\n")
  end

  @parametrics_toolbar_loaded = true
end
