class SIADE::RNAAdapter
  def initialize(siret)
    @siret = siret
  end

  def data_source
    @data_source ||= JSON.parse(SIADE::API.rna(@siret), symbolize_names: true)
  end

  def to_params
    if data_source[:association][:id].nil?
      return nil
    end
    params = data_source[:association].slice(*attr_to_fetch)
    params[:rna] = data_source[:association][:id]
    params
  rescue
    nil
  end

  private

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
