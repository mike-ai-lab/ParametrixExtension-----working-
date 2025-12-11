# Complete extension reload - clears all caches
$LOADED_FEATURES.delete_if { |f| f.include?('PARAMETRIX') }
Object.send(:remove_const, :PARAMETRIX) if defined?(PARAMETRIX)
Object.send(:remove_const, :PARAMETRIX_TRIMMING_V4) if defined?(PARAMETRIX_TRIMMING_V4)
Object.send(:remove_const, :CladzPARAMETRIXMultiFacePosition) if defined?(CladzPARAMETRIXMultiFacePosition)
load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/PARAMETRIX.rb'
puts "[RELOAD] Complete extension reloaded - all caches cleared"