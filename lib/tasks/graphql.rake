# frozen_string_literal: true

require "graphql/rake_task"
GraphQL::RakeTask.new(schema_name: "API::V2::Schema", directory: 'app/graphql')
