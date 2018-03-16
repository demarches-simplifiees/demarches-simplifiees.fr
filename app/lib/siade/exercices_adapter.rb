class SIADE::ExercicesAdapter
  def initialize(siret, procedure_id)
    @siret = siret
    @procedure_id = procedure_id
  end

  def data_source
    @data_source ||= JSON.parse(SIADE::API.exercices(@siret, @procedure_id), symbolize_names: true)
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
