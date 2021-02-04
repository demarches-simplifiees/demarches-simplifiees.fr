class ApiEntreprise::ExercicesJob < ApiEntreprise::Job
  rescue_from(ApiEntreprise::API::Error::BadFormatRequest) do |exception|
  end

  def perform(etablissement_id, procedure_id)
    find_etablissement(etablissement_id)
    etablissement_params = ApiEntreprise::ExercicesAdapter.new(etablissement.siret, procedure_id).to_params
    etablissement.update!(etablissement_params)
  end
end
