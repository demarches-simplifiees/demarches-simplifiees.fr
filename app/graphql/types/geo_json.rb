# frozen_string_literal: true

module Types
  class GeoJSON < Types::BaseObject
    class CoordinatesType < Types::BaseScalar
      description "GeoJSON coordinates"

      def self.coerce_result(ruby_value, context)
        ruby_value
      end
    end

    field :type, String, null: false
    field :coordinates, CoordinatesType, null: false
  end
end
