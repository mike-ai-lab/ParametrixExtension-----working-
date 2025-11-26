# frozen_string_literal: true
require 'json'

module JWT
  # JSON encoding and decoding
  # @api private
  class JSON
    class << self
      def generate(data)
        ::JSON.generate(data)
      end

      def parse(data)
        ::JSON.parse(data)
      rescue ::JSON::ParserError => e
        raise JWT::DecodeError, "Invalid JSON format: #{e.message}"
      end
    end
  end
end