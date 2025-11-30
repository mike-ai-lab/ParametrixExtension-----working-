# RELOAD ALL PARAMETRIX FILES
Object.send(:remove_const, :PARAMETRIX_TRIMMING_V4) rescue nil

load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/lib/PARAMETRIX/core.rb'
load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/lib/PARAMETRIX/trimming_v4_enhanced.rb'
load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/lib/PARAMETRIX/layout_engine.rb'
load 'f:/BACKUP_LAYOUTS/New folder/PARAMETRIX_EXTENSION/lib/PARAMETRIX/commands.rb'

puts "RELOADED: Core, Trimming V4, Layout Engine, Commands"
puts "Trimming Version: #{PARAMETRIX_TRIMMING_V4::VERSION}"
