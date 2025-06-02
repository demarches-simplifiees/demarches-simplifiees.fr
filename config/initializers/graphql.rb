# frozen_string_literal: true

GraphQL::RailsLogger.configure do |config|
  config.white_list = {
    'API::V2::GraphqlController' => ['execute']
  }
end

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
