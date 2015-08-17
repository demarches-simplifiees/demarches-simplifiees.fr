class SIADE::EtablissementAdapter

  def initialize(siret)
    @siret = siret
  end

  def data_source
    @data_source ||= JSON.parse(SIADE::API.etablissement(@siret), symbolize_names: true)
  end

  def to_params
    params = {}

    data_source[:etablissement].each do |k,v|
      if attr_to_fetch.include?(k)
        params[k] = v
      end
    end
    params[:adresse] = adresse
    data_source[:etablissement][:adresse].each do |k,v|
      if address_attribut_to_fetch.include?(k)
        params[k] = v
      end
    end
    params
  end

  def attr_to_fetch
    [:siret,
     :siege_social,
     :naf,
     :libelle_naf,
     ]
  end

  def adresse
    adresse = ''
    [:l1, :l2, :l3, :l4, :l5].each do |line|
      adresse = adresse +  data_source[:etablissement][:adresse][line] + "\r\n" unless data_source[:etablissement][:adresse][line].nil?
    end
    adresse
  end

  def address_attribut_to_fetch
    [:numero_voie,
      :type_voie,
      :nom_voie,
      :complement_adresse,
      :code_postal,
      :localite,
      :code_insee_localite]
  end
end
