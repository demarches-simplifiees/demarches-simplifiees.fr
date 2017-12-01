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
      {
        ca: exercice[:ca],
        dateFinExercice: exercice[:date_fin_exercice],
        date_fin_exercice_timestamp: exercice[:date_fin_exercice_timestamp]
      }
    end
  rescue
    nil
  end
end
