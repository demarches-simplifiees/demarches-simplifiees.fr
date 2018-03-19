class ApiEntreprise::RNAAdapter < ApiEntreprise::Adapter
  private

  def get_resource
    ApiEntreprise::API.rna(@siret, @procedure_id)
  end

  def process_params
    if data_source[:association][:id].present?
      params = data_source[:association].slice(*attr_to_fetch)
      params[:rna] = data_source[:association][:id]
      params.transform_keys { |k| "association_#{k}" }
    else
      {}
    end
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
