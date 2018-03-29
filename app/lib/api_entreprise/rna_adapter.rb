class ApiEntreprise::RNAAdapter
  def initialize(siret, procedure_id)
    @siret = siret
    @procedure_id = procedure_id
  end

  def to_params
    if data_source.present? && data_source[:association][:id].present?
      params = data_source[:association].slice(*attr_to_fetch)
      params[:rna] = data_source[:association][:id]
      params
    else
      {}
    end
  end

  private

  def data_source
    @data_source ||= ApiEntreprise::API.rna(@siret, @procedure_id)
  rescue
    @data_source = nil
  end

  def attr_to_fetch
    [
      :titre,
      :objet,
      :date_creation,
      :date_declaration,
      :date_publication
    ]
  end
end
