Object.send(:remove_const, :PARAMETRIX) if defined?(PARAMETRIX)
Object.send(:remove_const, :PARAMETRIX_TRIMMING_V4) if defined?(PARAMETRIX_TRIMMING_V4)
Object.send(:remove_const, :CladzPARAMETRIXMultiFacePosition) if defined?(CladzPARAMETRIXMultiFacePosition)
load File.join(__dir__, 'PARAMETRIX.rb')
puts "[RELOAD] Done"
