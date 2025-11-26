# frozen_string_literal: true

module JWT
  # Encoding logic for JWT
  class Encode
    def initialize(payload, key, algorithm, header_fields)
      @payload = payload
      @key = key
      @algorithm = algorithm
      @header_fields = header_fields
    end

    def segments
      header = JWT::Base64.url_encode(JWT::JSON.generate(header_with_algorithm_and_type))
      payload = JWT::Base64.url_encode(JWT::JSON.generate(@payload))
      signature = JWT::Signature.sign(@algorithm, @key, "#{header}.#{payload}")
      [header, payload, signature].join('.')
    end

    private

    def header_with_algorithm_and_type
      @header_fields.merge('alg' => @algorithm, 'typ' => 'JWT')
    end
  end
end