class ApiEntreprise::ExercicesJob < ApiEntreprise::Job
  rescue_from(ApiEntreprise::API::BadFormatRequest) do |exception|
  end

  def perform(etablissement_id, procedure_id)
    etablissement = Etablissement.find(etablissement_id)
    etablissement_params = ApiEntreprise::ExercicesAdapter.new(etablissement.siret, procedure_id).to_params
    etablissement.update!(etablissement_params)
  end
end
