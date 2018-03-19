class ApiEntreprise::ExercicesAdapter < ApiEntreprise::Adapter
  def to_params
    if data_source.present?
      exercices_array = data_source[:exercices].map do |exercice|
        exercice.slice(*attr_to_fetch)
      end

      { exercices_attributes: exercices_array }
    else
      {}
    end
  end

  private

  def get_resource
    ApiEntreprise::API.exercices(@siret_or_siren, @procedure_id)
  end

  def attr_to_fetch
    [
      :ca,
      :date_fin_exercice,
      :date_fin_exercice_timestamp
    ]
  end
end
