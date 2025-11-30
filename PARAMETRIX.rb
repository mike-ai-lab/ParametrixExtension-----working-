# PARAMETRIX Layout Generator Extension

require 'sketchup.rb'

# Load main extension components first
load File.join(__dir__, 'lib', 'PARAMETRIX', 'loader.rb')
# Note: trimming_v4_enhanced.rb is loaded by loader.rb
# TEMPORARY: License managers commented out for testing
# load File.join(__dir__, 'lib', 'PARAMETRIX', 'license_manager.rb')
# load File.join(__dir__, 'lib', 'PARAMETRIX', 'trial_manager.rb')
load File.join(__dir__, 'geometry_diagnostic.rb')

# TEMPORARY: License validation disabled for testing
# UI.start_timer(1.0, false) do
#   puts "[PARAMETRIX] Starting license validation..."
#   if defined?(PARAMETRIX) && defined?(PARAMETRIX::LicenseManager)
#     puts "[PARAMETRIX] License manager found, validating..."
#     if PARAMETRIX::LicenseManager.validate_license
#       puts "[PARAMETRIX] License validated successfully"
#       # Start trial countdown if trial is active
#       PARAMETRIX::TrialManager.start_trial_countdown if defined?(PARAMETRIX::TrialManager)
#     else
#       puts "[PARAMETRIX] License validation failed"
#       UI.messagebox(
#         "PARAMETRIX Extension requires a valid license.\n\nPlease contact support for licensing information.", 
#         MB_OK, 
#         "License Required"
#       )
#     end
#   else
#     puts "[PARAMETRIX] License manager not found"
#   end
# end

# TESTING MODE: Extension loaded without license validation
puts "[PARAMETRIX] ══════════════════════════════════════════════════════════"
puts "[PARAMETRIX] VERSION: #{PARAMETRIX::PARAMETRIX_EXTENSION_VERSION}"
puts "[PARAMETRIX] TRIMMING: OOB Method (2D intersect → 3D extrude)"
puts "[PARAMETRIX] TESTING MODE: License validation bypassed"
puts "[PARAMETRIX] ══════════════════════════════════════════════════════════"

# Add diagnostic menu item
if defined?(PARAMETRIX)
  unless file_loaded?('parametrix_diagnostic')
    menu = UI.menu('Plugins')
    submenu = menu.add_submenu('PARAMETRIX')
    submenu.add_item('Diagnose Selected Geometry') {
      PARAMETRIX.diagnose_selected_geometry
    }
    file_loaded('parametrix_diagnostic')
  end
end

file_loaded(__FILE__)