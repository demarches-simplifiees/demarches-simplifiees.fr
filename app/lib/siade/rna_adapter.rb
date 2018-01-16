class SIADE::RNAAdapter
  def initialize(siret)
    @siret = siret
  end

  def data_source
    @data_source ||= JSON.parse(SIADE::API.rna(@siret), symbolize_names: true)
  end

  def to_params
    params = {}

    data_source[:association].each do |k, v|
      params[k] = v if attr_to_fetch.include?(k)
    end

    params[:association_id] = params[:id]
    params.delete(:id)

    params
  rescue
    nil
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
