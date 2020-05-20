class ApiEntreprise::Adapter
  UNAVAILABLE = 'Donnée indisponible'

  def initialize(siret, procedure_id)
    @siret = siret
    @procedure_id = procedure_id
  end

  def data_source
    begin
      @data_source ||= get_resource
    rescue ApiEntreprise::API::ResourceNotFound
      @data_source = nil
    end
  end

  def to_params
    if data_source.present?
      process_params
    else
      {}
    end
  end

  def valid_params?(params)
    !params.has_value?(UNAVAILABLE)
  end

  def siren
    @siret[0..8]
  end
end
