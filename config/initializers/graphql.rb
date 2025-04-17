# frozen_string_literal: true

require "graphql/introspection/dynamic_fields"

module GraphQL
  class Schema
    class Member
      module BuildType
        def self.camelize(string)
          string.camelize(:lower)
        end
      end
    end
  end
end
