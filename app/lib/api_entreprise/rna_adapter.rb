class ApiEntreprise::RNAAdapter < ApiEntreprise::Adapter
  private

  def get_resource
    ApiEntreprise::API.rna(@siret, @procedure_id)
  end

  def process_params
    # Responses with a 206 codes are sometimes not useable,
    # as the RNA calls often return a 206 with an error message,
    # not a partial response
    if !data_source.key?(:association)
      {}
    else
      params = data_source[:association].slice(*attr_to_fetch)

      if params[:id].present? && valid_params?(params)
        params[:rna] = params[:id]
        params.except(:id).transform_keys { |k| :"association_#{k}" }
      else
        {}
      end
    end
  end

  def attr_to_fetch
    [
      :id,
      :titre,
      :objet,
      :date_creation,
      :date_declaration,
      :date_publication
    ]
  end
end
