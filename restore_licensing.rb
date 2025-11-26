# PARAMETRIX License Restoration Script
# Run this script to restore the licensing system after testing

puts "Restoring PARAMETRIX licensing system..."

# Restore main PARAMETRIX.rb file
main_file = File.join(__dir__, 'PARAMETRIX.rb')
content = File.read(main_file)

# Restore license manager loading
content.gsub!(
  "# TEMPORARY: License managers commented out for testing\n# load File.join(__dir__, 'lib', 'PARAMETRIX', 'license_manager.rb')\n# load File.join(__dir__, 'lib', 'PARAMETRIX', 'trial_manager.rb')",
  "load File.join(__dir__, 'lib', 'PARAMETRIX', 'license_manager.rb')\nload File.join(__dir__, 'lib', 'PARAMETRIX', 'trial_manager.rb')"
)

# Restore license validation timer
content.gsub!(
  /# TEMPORARY: License validation disabled for testing.*?# TESTING MODE: Extension loaded without license validation\nputs "\[PARAMETRIX\] TESTING MODE: License validation bypassed"/m,
  "# Validate license after loading\nUI.start_timer(1.0, false) do\n  puts \"[PARAMETRIX] Starting license validation...\"\n  if defined?(PARAMETRIX) && defined?(PARAMETRIX::LicenseManager)\n    puts \"[PARAMETRIX] License manager found, validating...\"\n    if PARAMETRIX::LicenseManager.validate_license\n      puts \"[PARAMETRIX] License validated successfully\"\n      # Start trial countdown if trial is active\n      PARAMETRIX::TrialManager.start_trial_countdown if defined?(PARAMETRIX::TrialManager)\n    else\n      puts \"[PARAMETRIX] License validation failed\"\n      UI.messagebox(\n        \"PARAMETRIX Extension requires a valid license.\\n\\nPlease contact support for licensing information.\", \n        MB_OK, \n        \"License Required\"\n      )\n    end\n  else\n    puts \"[PARAMETRIX] License manager not found\"\n  end\nend"
)

File.write(main_file, content)

# Restore commands.rb file
commands_file = File.join(__dir__, 'lib', 'PARAMETRIX', 'commands.rb')
commands_content = File.read(commands_file)

commands_content.gsub!(
  "    # TEMPORARY: License check disabled for testing\n    # unless PARAMETRIX::LicenseManager.has_valid_license?\n    #   UI.messagebox(\"A valid PARAMETRIX license is required to use this feature. Please restart SketchUp to activate your license.\")\n    #   return\n    # end",
  "    # First, ensure there is a valid license.\n    unless PARAMETRIX::LicenseManager.has_valid_license?\n      UI.messagebox(\"A valid PARAMETRIX license is required to use this feature. Please restart SketchUp to activate your license.\")\n      return\n    end"
)

File.write(commands_file, commands_content)

puts "✓ Licensing system restored successfully!"
puts "Please restart SketchUp for changes to take effect."