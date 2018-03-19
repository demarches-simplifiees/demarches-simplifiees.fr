class ApiEntreprise::Adapter
  def initialize(siret_or_siren, procedure_id)
    @siret_or_siren = siret_or_siren
    @procedure_id = procedure_id
  end

  def data_source
    @data_source ||= get_resource
  rescue
    @data_source = nil
  end
end
