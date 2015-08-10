class SIADE::EntrepriseAdapter

  def initialize(siren)
    @siren = siren
  end

  def data_source
    @data_source ||= JSON.parse(SIADE::Api.entreprise(@siren), symbolize_names: true)
  rescue
    @data_source = nil
  end

  def to_params
    params = {}

    data_source[:entreprise].each do |k,v|
      if attr_to_fetch.include?(k)
        params[k] = v
      end
    end
    params
  rescue
    nil
  end

  def attr_to_fetch
    [:siren,
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
     :prenom]
  end
end
