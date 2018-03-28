class ApiEntreprise::EntrepriseAdapter < ApiEntreprise::Adapter
  def to_params
    if data_source.present?
      params = data_source[:entreprise].slice(*attr_to_fetch)
      params[:date_creation] = Time.at(params[:date_creation]).to_datetime
      params
    else
      {}
    end
  end

  private

  def data_source
    @data_source ||= ApiEntreprise::API.entreprise(@siret_or_siren, @procedure_id)
  rescue
    @data_source = nil
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
