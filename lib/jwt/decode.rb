# frozen_string_literal: true

require 'json'

module JWT
  # Decoding logic for JWT
  class Decode
    def initialize(jwt, key, verify, options, &keyfinder)
      raise(JWT::DecodeError, 'Nil JSON web token') unless jwt
      @jwt = jwt
      @key = key
      @verify = verify
      @options = options
      @keyfinder = keyfinder
    end

    def decode_segments
      header, payload, signature = raw_segments
      decoded_header = JWT::JSON.parse(JWT::Base64.url_decode(header))
      decoded_payload = JWT::JSON.parse(JWT::Base64.url_decode(payload))

      if @verify
        algo, key = find_algorithm_and_key(decoded_header, &@keyfinder)
        verify_signature(algo, header, payload, signature, key)
      end

      if @options[:verify_claims]
        verify_claims(decoded_payload)
      end


      [decoded_payload, decoded_header]
    end

    private

    def verify_claims(payload)
      JWT::Claims::Verifier.new(payload, @options).verify!
    end

    def find_algorithm_and_key(header, &keyfinder)
      alg = @options[:algorithm] || header['alg']
      key = if keyfinder
              keyfinder.arity == 2 ? keyfinder.call(header, payload) : keyfinder.call(header)
            else
              @key
            end
      [alg, key]
    end

    def raw_segments
      @jwt.split('.', 3)
    end

    def verify_signature(algo, header, payload, signature, key)
      raise(JWT::DecodeError, 'Signature verification failed') unless signature

      return if algo.casecmp('none').zero?

      JWT::Signature.verify(algo, key, "#{header}.#{payload}", signature)
    end
  end
end