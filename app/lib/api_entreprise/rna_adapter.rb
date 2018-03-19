class ApiEntreprise::RNAAdapter < ApiEntreprise::Adapter
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

  def get_resource
    ApiEntreprise::API.rna(@siret_or_siren, @procedure_id)
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
