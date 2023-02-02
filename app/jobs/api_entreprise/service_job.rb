class APIEntreprise::ServiceJob < APIEntreprise::Job
  def perform(service_id)
    service = Service.find(service_id)

    service_params = APIEntreprise::ServiceAdapter.new(service.siret, service_id).to_params
    service.etablissement_infos = service_params

    point = Geocoder.search(service_params[:adresse]).first

    service.etablissement_lat = point&.latitude
    service.etablissement_lng = point&.longitude

    service.save!
  end
end
