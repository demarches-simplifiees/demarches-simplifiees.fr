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
    params = {}

    data_source[:exercices].each_with_index do |values, i|
      params[i] = {}

      values.each do |index, value|
        params[i][index] = value if attr_to_fetch.include?(index)
      end
    end
    params
  rescue
    nil
  end

  def attr_to_fetch
    [:ca,
     :dateFinExercice,
     :date_fin_exercice_timestamp]
  end
end