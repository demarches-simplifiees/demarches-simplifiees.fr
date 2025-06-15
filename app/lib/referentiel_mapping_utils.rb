# frozen_string_literal: true

module ReferentielMappingUtils
  SUPPORTED_SIMPLE_TYPES = [String, Integer, Float].freeze

  def self.array_of_supported_simple_types?(arr)
    arr.is_a?(Array) && arr.all? { |v| SUPPORTED_SIMPLE_TYPES.any? { |type| v.is_a?(type) } }
  end
end
