# frozen_string_literal: true

module JWT
  # Default configuration for JWT
  class Configuration
    attr_accessor :verify_expiration, :verify_not_before, :verify_iss, :verify_iat, :verify_jti, :verify_aud, :verify_sub, :leeway

    def initialize
      @verify_expiration = true
      @verify_not_before = true
      @verify_iss = false
      @verify_iat = false
      @verify_jti = false
      @verify_aud = false
      @verify_sub = false
      @leeway = 0
    end
  end
end