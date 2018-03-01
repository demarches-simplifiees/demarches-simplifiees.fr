class SIADE::ExercicesAdapter
  def initialize(siret)
    @siret = siret
  end

  def data_source
    @data_source ||= JSON.parse(SIADE::API.exercices(@siret), symbolize_names: true)
  rescue
    @data_source = nil
  end

  def to_params
    data_source[:exercices].map do |exercice|
      exercice.slice(*attr_to_fetch)
    end
  rescue
    []
  end

  private

  def attr_to_fetch
    [:ca, :date_fin_exercice, :date_fin_exercice_timestamp]
  end
end
