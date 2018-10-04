class ApiEntreprise::RNAAdapter < ApiEntreprise::Adapter
  private

  def get_resource
    ApiEntreprise::API.rna(@siret, @procedure_id)
  end

  def process_params
    # Sometimes the associations endpoints responses with a 206,
    # and these response are often useable as the they only
    # contain an error message.
    # Therefore here we make sure that our response seems valid
    # by checking that there is an association attribute.
    if !data_source.key?(:association)
      {}
    else
      association_id = data_source[:association][:id]
      params = data_source[:association].slice(*attr_to_fetch)

      if association_id.present? && valid_params?(params)
        params[:rna] = association_id
        params.transform_keys { |k| :"association_#{k}" }
      else
        {}
      end
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
