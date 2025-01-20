# frozen_string_literal: true

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
