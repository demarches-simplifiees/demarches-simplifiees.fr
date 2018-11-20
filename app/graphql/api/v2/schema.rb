class Api::V2::Schema < GraphQL::Schema
  default_max_page_size 100
  max_complexity 300
  max_depth 10

  query Types::QueryType
  mutation Types::MutationType

  def self.id_from_object(object, type_definition, ctx)
    object.to_typed_id
  end

  def self.object_from_id(id, query_ctx)
    ApplicationRecord.record_from_typed_id(id)
  rescue => e
    raise GraphQL::ExecutionError, e.message, extensions: { code: :not_found }
  end

  def self.resolve_type(type, obj, ctx)
    case obj
    when Procedure
      Types::DemarcheType
    when Dossier
      Types::DossierType
    when Gestionnaire, User
      Types::ProfileType
    else
      raise GraphQL::ExecutionError, "Unexpected object: #{obj}"
    end
  end

  def self.unauthorized_object(error)
    # Add a top-level error to the response instead of returning nil:
    raise GraphQL::ExecutionError, "An object of type #{error.type.graphql_name} was hidden due to permissions", extensions: { code: :unauthorized }
  end

  middleware(GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 5) do |err, query|
    Rails.logger.info("GraphQL Timeout: #{query.query_string}")
  end)

  if Rails.env.development?
    query_analyzer(GraphQL::Analysis::QueryComplexity.new do |query, complexity|
      Rails.logger.info("[GraphQL Query Complexity] #{complexity}")
    end)
    query_analyzer(GraphQL::Analysis::QueryDepth.new do |query, depth|
      Rails.logger.info("[GraphQL Query Depth] #{depth}")
    end)
  end

  use GraphQL::Batch
  use GraphQL::Tracing::SkylightTracing
end
