class SIADE::RNAAdapter
  def initialize(siren)
    @siret = siren
  end

  def data_source
    @data_source ||= JSON.parse(SIADE::API.rna(@siren), symbolize_names: true)
  end

  def to_params
    params = {}

    data_source[:association].each do |k, v|
      params[k] = v if attr_to_fetch.include?(k)
    end
    params
  end

  def attr_to_fetch
    [:id,
     :titre,
     :objet,
     :date_creation,
     :date_declaration,
     :date_publication
    ]
  end
end
