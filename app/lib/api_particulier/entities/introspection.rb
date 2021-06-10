# frozen_string_literal: true

module APIParticulier
  module Entities
    class Introspection
      def initialize(**kwargs)
        attrs = kwargs.symbolize_keys
        @id = attrs[:id]
        @name = attrs[:name]
        @email = attrs[:email]
        @scopes = attrs[:scopes]
      end

      attr_reader :id, :name, :email, :scopes
    end
  end
end
