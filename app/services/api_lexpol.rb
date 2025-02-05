require 'typhoeus'
require 'json'

class APILexpol
  BASE_URL = ENV.fetch('API_LEXPOL_BASE_URL', 'https://devapilexpol.cloud.pf/api/v1/geda')

  def initialize
    @credentials = {
      email: ENV.fetch('API_LEXPOL_EMAIL'),
      motdepasse: ENV.fetch('API_LEXPOL_PASSWORD'),
      email_agent: ENV.fetch('API_LEXPOL_AGENT_EMAIL')
    }
    @token = nil
    @token_expiration = nil
  end

  def authenticate
    return @token if @token && @token_expiration && @token_expiration > Time.zone.now

    if defined?(Rails) && Rails.cache
      @token, @token_expiration = Rails.cache.fetch("lexpol_token", expires_in: 300) do
        perform_authentication
      end
    else
      @token, @token_expiration = perform_authentication
    end

    @token
  end

  def get_models
    authenticate
    response = Typhoeus.get("#{BASE_URL}/modeles", params: { jeton: @token })
    handle_response(response, 'Erreur lors de la récupération des modèles') do |body|
      body
    end
  end

  def create_dossier(modele_id, variables = {})
    authenticate
    params = { jeton: @token, modele: modele_id }
    params[:variables] = variables if variables.present?

    response = Typhoeus.post("#{BASE_URL}/dossier", body: params.to_json, headers: { 'Content-Type' => 'application/json' })
    handle_response(response, 'Erreur lors de la création du dossier') do |body|
      body['nor']
    end
  end

  def update_dossier(nor, variables)
    authenticate
    response = Typhoeus.put("#{BASE_URL}/dossier/#{nor}/modifier",
                            body: { jeton: @token, variables: variables }.to_json,
                            headers: { 'Content-Type' => 'application/json' })
    handle_response(response, 'Erreur lors de la mise à jour du dossier') do |body|
      body['nor']
    end
  end

  def get_dossier_status(nor)
    authenticate
    response = Typhoeus.get("#{BASE_URL}/dossier/#{nor}/statut", params: { jeton: @token })
    handle_response(response, 'Erreur lors de la récupération du statut du dossier') do |body|
      { statut: body['statut'], libelle: body['libelle'] }
    end
  end

  def get_dossier_infos(nor)
    authenticate
    response = Typhoeus.get("#{BASE_URL}/dossier/#{nor}/infos", params: { jeton: @token })
    handle_response(response, 'Erreur lors de la récupération des informations du dossier') do |body|
      body
    end
  end

  private

  def perform_authentication
    options = {
      body: @credentials.to_json,
      headers: { 'Content-Type' => 'application/json' }
    }

    if ENV['USE_CERTIFICATE_FOR_LEXPOL'] == 'true'
      options[:sslcert] = ENV.fetch('API_LEXPOL_CERT_PATH')
      options[:ssl_key] = ENV.fetch('API_LEXPOL_KEY_PATH')
    end

    response = Typhoeus.post("#{BASE_URL}/authentification", options)

    if response.success?
      body = JSON.parse(response.body)
      [body['jeton'], Time.zone.now + 300] # 300 secondes = 5 minutes
    else
      raise "Erreur d'authentification Lexpol : #{response.body}"
    end
  end

  def handle_response(response, error_message)
    if response.success?
      body = JSON.parse(response.body.force_encoding('UTF-8'))
      yield(body)
    else
      raise "#{error_message} : #{response.body}"
    end
  end
end
