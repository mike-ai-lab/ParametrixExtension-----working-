# PARAMETRIX License Manager Stub
module PARAMETRIX
  module LicenseManager
    LICENSE_FILE_PATH = File.join(ENV['APPDATA'] || ENV['HOME'], 'parametrix_license.txt')
    RSA_PUBLIC_KEY = "stub_key"
    
    def self.has_valid_license?
      true
    end
    
    def self.validate_license
      true
    end
    
    def self.validate_jwt_token(token)
      true
    end
  end
end