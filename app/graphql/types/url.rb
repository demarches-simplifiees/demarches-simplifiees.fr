module Types
  class URL < Types::BaseScalar
    description "A valid URL, transported as a string"

    def self.coerce_input(input_value, context)
      uri = Addressable::URI.parse(input_value)
      if uri.scheme.in?(['http', 'https'])
        uri.to_s
      else
        raise GraphQL::CoercionError, "#{input_value.inspect} is not a valid URL"
      end
    rescue Addressable::URI::InvalidURIError
      raise GraphQL::CoercionError, "#{input_value.inspect} is not a valid URL"
    end

    def self.coerce_result(ruby_value, context)
      ruby_value.to_s
    end
  end
end
