class ApiEntreprise::EntrepriseAdapter < ApiEntreprise::Adapter
  private

  def get_resource
    ApiEntreprise::API.entreprise(siren, @procedure_id)
  end

  def process_params
    params = data_source[:entreprise]&.slice(*attr_to_fetch)

    if params.present? && valid_params?(params)
      params[:date_creation] = Time.zone.at(params[:date_creation]).to_datetime
      params.transform_keys { |k| :"entreprise_#{k}" }
    else
      {}
    end
  end

  def attr_to_fetch
    [
      :siren,
      :capital_social,
      :numero_tva_intracommunautaire,
      :forme_juridique,
      :forme_juridique_code,
      :nom_commercial,
      :raison_sociale,
      :siret_siege_social,
      :code_effectif_entreprise,
      :date_creation,
      :nom,
      :prenom
    ]
  end
end
