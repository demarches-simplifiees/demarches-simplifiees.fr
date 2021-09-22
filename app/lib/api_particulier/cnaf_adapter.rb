class APIParticulier::CNAFAdapter
  def initialize(api_particulier_token, numero_allocataire, code_postal, requested_sources)
    @api = APIParticulier::API.new(api_particulier_token)
    @numero_allocataire = numero_allocataire
    @code_postal = code_postal
    @requested_sources = requested_sources
  end

  def to_params
    @api.composition_familiale(@numero_allocataire, @code_postal)
      .then { |d| extract_requested_sources(d) }
  end

  private

  def extract_requested_sources(data)
    @requested_sources['cnaf']&.map do |(scope, sources)|
      case scope
      when 'enfants', 'allocataires'
        { scope => data[scope].map { |s| s.slice(*sources) } }
      when 'quotient_familial'
        { scope => data.slice(*sources) }
      else
        { scope => data[scope].slice(*sources) }
      end
    end
      &.reduce(&:deep_merge) || {}
  end
end
