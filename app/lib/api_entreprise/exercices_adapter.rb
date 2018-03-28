class ApiEntreprise::ExercicesAdapter < ApiEntreprise::Adapter
  def to_array
    if data_source.present?
      data_source[:exercices].map do |exercice|
        exercice.slice(*attr_to_fetch)
      end
    else
      []
    end
  end

  private

  def data_source
    @data_source ||= ApiEntreprise::API.exercices(@siret_or_siren, @procedure_id)
  rescue
    @data_source = nil
  end

  def attr_to_fetch
    [
      :ca,
      :date_fin_exercice,
      :date_fin_exercice_timestamp
    ]
  end
end
