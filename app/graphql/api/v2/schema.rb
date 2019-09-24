class Api::V2::Schema < GraphQL::Schema
  default_max_page_size 100
  max_complexity 300
  max_depth 15

  def self.unauthorized_object(error)
    # Add a top-level error to the response instead of returning nil:
    raise GraphQL::ExecutionError.new("An object of type #{error.type.graphql_name} was hidden due to permissions", extensions: { code: :unauthorized })
  end

  middleware(GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 5) do |_, query|
    Rails.logger.info("GraphQL Timeout: #{query.query_string}")
  end)

  if Rails.env.development?
    query_analyzer(GraphQL::Analysis::QueryComplexity.new do |_, complexity|
      Rails.logger.info("[GraphQL Query Complexity] #{complexity}")
    end)
    query_analyzer(GraphQL::Analysis::QueryDepth.new do |_, depth|
      Rails.logger.info("[GraphQL Query Depth] #{depth}")
    end)
  end

  use GraphQL::Batch
  use GraphQL::Tracing::SkylightTracing
end
