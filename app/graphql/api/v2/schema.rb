class Api::V2::Schema < GraphQL::Schema
  default_max_page_size 100
  max_complexity 300
  max_depth 15

  query Types::QueryType
  mutation Types::MutationType

  def self.id_from_object(object, type_definition, ctx)
    object.to_typed_id
  end

  def self.object_from_id(id, query_ctx)
    ApplicationRecord.record_from_typed_id(id)
  rescue => e
    raise GraphQL::ExecutionError.new(e.message, extensions: { code: :not_found })
  end

  def self.resolve_type(type, obj, ctx)
    case obj
    when Procedure
      Types::DemarcheType
    when Dossier
      Types::DossierType
    when Commentaire
      Types::MessageType
    when Instructeur, User
      Types::ProfileType
    when Individual
      Types::PersonnePhysiqueType
    when Etablissement
      Types::PersonneMoraleType
    else
      raise GraphQL::ExecutionError.new("Unexpected object: #{obj}")
    end
  end

  orphan_types Types::Champs::CarteChampType,
    Types::Champs::CheckboxChampType,
    Types::Champs::CiviliteChampType,
    Types::Champs::DateChampType,
    Types::Champs::DecimalNumberChampType,
    Types::Champs::DossierLinkChampType,
    Types::Champs::IntegerNumberChampType,
    Types::Champs::LinkedDropDownListChampType,
    Types::Champs::MultipleDropDownListChampType,
    Types::Champs::PieceJustificativeChampType,
    Types::Champs::RepetitionChampType,
    Types::Champs::SiretChampType,
    Types::Champs::TextChampType,
    Types::GeoAreas::ParcelleCadastraleType,
    Types::GeoAreas::QuartierPrioritaireType,
    Types::GeoAreas::SelectionUtilisateurType,
    Types::PersonneMoraleType,
    Types::PersonnePhysiqueType

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
