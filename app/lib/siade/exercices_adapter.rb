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
    data_source[:exercices]
  rescue
    nil
  end

  def attr_to_fetch
    [:ca,
     :dateFinExercice,
     :date_fin_exercice_timestamp]
  end
end
