class APIEntreprise::EntrepriseAdapter < APIEntreprise::Adapter
  private

  def get_resource
    api(@procedure_id).entreprise(siren)
  end

  def process_params
    params = data_source[:entreprise]&.slice(*attr_to_fetch)
    params[:etat_administratif] = map_etat_administratif(data_source)

    if params.present? && valid_params?(params)
      params[:date_creation] = Time.zone.at(params[:date_creation]).to_datetime if params[:date_creation].present?
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

  def map_etat_administratif(data_source)
    raw_value = data_source.dig(:entreprise, :etat_administratif, :value) # data structure will change in v3

    case raw_value
    when 'A' then 'actif'
    when 'F' then 'fermé'
    end
  end
end
