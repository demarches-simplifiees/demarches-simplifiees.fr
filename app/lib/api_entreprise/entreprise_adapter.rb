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
      if params[:raison_sociale].present? && is_individual_entreprise?(params[:forme_juridique_code])
        params[:raison_sociale] = humanize_raison_sociale(params[:raison_sociale])
      end
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

  def humanize_raison_sociale(params_raison_sociale)
    # see SIREN official spec : https://sirene.fr/sirene/public/variable/syr-nomen-long
    splitted_raison_sociale = params_raison_sociale.split(/[*,\/]/)

    nom_patronymique = splitted_raison_sociale.first
    prenom = splitted_raison_sociale.last.titleize.strip

    if splitted_raison_sociale.count == 3
      nom_usage = splitted_raison_sociale.second
      raison_sociale = "#{prenom} #{nom_usage} (#{nom_patronymique})"
    else
      raison_sociale = "#{prenom} #{nom_patronymique}"
    end
    raison_sociale
  end

  def is_individual_entreprise?(forme_juridique_code)
    forme_juridique_code == "1000"
  end
end
