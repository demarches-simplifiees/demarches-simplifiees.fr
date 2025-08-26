# frozen_string_literal: true

class APIEntreprise::ServiceAdapter < APIEntreprise::EtablissementAdapter
  def initialize(siret, service_id)
    @siret = siret
    @service_id = service_id
  end

  private

  def get_resource
    api_instance = api
    # TODO: reuse instead a token from an administrateur's procedure?
    api_instance.api_token = APIEntrepriseToken.new(ENV['API_ENTREPRISE_KEY'])
    api_instance.api_object = "service_id: #{@service_id}"
    api_instance.etablissement(@siret)
  end

  def attr_to_fetch
    [
      :adresse,
      :siret
    ]
  end
end
