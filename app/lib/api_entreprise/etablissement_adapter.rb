class ApiEntreprise::EtablissementAdapter < ApiEntreprise::Adapter
  private

  def get_resource
    ApiEntreprise::API.etablissement(@siret, @procedure_id)
  end

  def process_params
    params = data_source[:etablissement].slice(*attr_to_fetch)

    if valid_params?(params)
      adresse_line = params[:adresse].slice(*address_lines_to_fetch).values.compact.join("\r\n")
      params.merge!(params[:adresse].slice(*address_attr_to_fetch))
      params[:adresse] = adresse_line
      params
    else
      {}
    end
  end

  def attr_to_fetch
    [
      :adresse,
      :siret,
      :siege_social,
      :naf,
      :libelle_naf,
      :enseigne,
      :diffusable_commercialement
    ]
  end

  def address_attr_to_fetch
    [
      :numero_voie,
      :type_voie,
      :nom_voie,
      :complement_adresse,
      :code_postal,
      :localite,
      :code_insee_localite
    ]
  end

  def address_lines_to_fetch
    [:l1, :l2, :l3, :l4, :l5, :l6, :l7]
  end
end
