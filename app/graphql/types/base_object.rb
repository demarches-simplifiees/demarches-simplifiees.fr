# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    field_class BaseField

    class InvalidNullError < GraphQL::InvalidNullError
      def to_h
        super.merge(extensions: { code: :invalid_null })
      end
    end
  end
end
