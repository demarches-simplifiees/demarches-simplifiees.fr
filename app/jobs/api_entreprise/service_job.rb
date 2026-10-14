# frozen_string_literal: true

class APIEntreprise::ServiceJob < ApplicationJob
  include Dry::Monads[:result]

  queue_as :default

  use_sidekiq_retry(report_after_attempts: 8)

  discard_on ActiveRecord::RecordNotFound

  def perform(service_id)
    service = Service.find(service_id)

    case APIEntreprise::ServiceAdapter.new(service.siret, service_id).to_params
    in Success(service_params) if service_params.present?
      update_service(service, service_params)
    in Failure(retryable: true, type:, **)
      raise RetryableFetchError.new("API Entreprise: #{type}", provider: self.class.name)
    in Success | Failure(retryable: false, **)
      nil
    end
  end

  private

  def update_service(service, service_params)
    service.etablissement_infos = service_params

    code_insee = service.etablissement_infos['code_insee_localite']
    nom_pays = service.etablissement_infos["nom_pays"]

    if code_insee.present?
      service.departement = CodeInsee.new(code_insee).to_departement
    elsif nom_pays.present? && nom_pays != "FRANCE"
      service.departement = "99"
    end

    if service_params[:adresse].present?
      point = Geocoder.search(service_params[:adresse], params: { citycode: code_insee, limit: 1 }).first

      service.etablissement_lat = point&.latitude
      service.etablissement_lng = point&.longitude
    else
      service.etablissement_lat = nil
      service.etablissement_lng = nil
    end

    service.save!
  end
end
