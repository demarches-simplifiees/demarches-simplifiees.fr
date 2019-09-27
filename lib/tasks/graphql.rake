require "graphql/rake_task"
GraphQL::RakeTask.new(schema_name: "Api::V2::Schema", directory: 'app/graphql')
