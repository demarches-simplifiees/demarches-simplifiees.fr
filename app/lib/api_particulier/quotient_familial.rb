# frozen_string_literal: true

class APIParticulier::QuotientFamilial
  class RequestFailed < StandardError
    def initialize(response)
      msg = <<-TEXT
        HTTP error code: #{response.code}
        #{response.body}
      TEXT

      super(msg)
    end
  end

  QUOTIENT_FAMILIAL = "v3/dss/quotient_familial/identite"
  TIMEOUT = 20

  def initialize(procedure_id = nil)
    return if procedure_id.blank?

    @procedure = Procedure.find(procedure_id)
    @token = @procedure.api_particulier_token
  end

  def quotient_familial(fci)
    call_with_fci(QUOTIENT_FAMILIAL, fci)
  end

  private

  def call_with_fci(resource_name, fci)
    url = [API_PARTICULIER_URL, resource_name].join("/")

    params = build_params(fci)

    call(url, params)
  end

  def build_params(fci)
    params = {
      recipient: recipient_for_procedure,
      **user_params_for(fci)
    }
  end

  def recipient_for_procedure
    service_siret = @procedure&.service && @procedure.service.siret.presence
    return service_siret if service_siret
    ENV.fetch('API_PARTICULIER_DEFAULT_SIRET')
  end

  def user_params_for(fci)
    birthdate = Date.parse(fci.birthdate) rescue nil

    gender_for_api = case fci.gender&.downcase
                when "female" then "F"
                when "male" then "M"
                else nil
                end

    given_name_for_api = fci.given_name.split(" ")

    {
      codeCogInseePaysNaissance: fci.birthcountry,
      codeCogInseeCommuneNaissance: fci.birthplace,
      sexeEtatCivil: gender_for_api,
      nomNaissance: fci.family_name,
      "prenoms[]" => given_name_for_api,
      anneeDateNaissance: fci.birthdate.year.to_s,
      moisDateNaissance: fci.birthdate.month.to_s,
      jourDateNaissance: fci.birthdate.day.to_s,
    }
  end

  def call(url, params)
    response = Typhoeus.get(url,
      headers: { Authorization: "Bearer #{@token}" },
      params: params,
      params_encoding: :multi,
      timeout: TIMEOUT)

    return nil if !response.success?

    JSON.parse(response.body, symbolize_names: true)
  end
end
