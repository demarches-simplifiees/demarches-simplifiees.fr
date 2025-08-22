# frozen_string_literal: true

require 'oauth2'

class RdvService
  include Dry::Monads[:result]

  def initialize(rdv_connection:)
    @rdv_connection = rdv_connection
  end

  def self.rdv_sp_host_url
    ENV["RDV_SERVICE_PUBLIC_URL"]
  end

  def self.rdv_sp_org_config_url
    "#{rdv_sp_host_url}/admin/organisations/configuration"
  end

  def self.rdv_sp_agenda_url
    "#{rdv_sp_host_url}/agents/agenda"
  end

  def self.create_rdv_plan_url
    "#{rdv_sp_host_url}/api/v1/rdv_plans"
  end

  def self.update_pending_rdv_plan_url(rdv_plan_external_id)
    "#{rdv_sp_host_url}/api/v1/rdv_plans/#{rdv_plan_external_id}"
  end

  def self.rdv_sp_rdv_user_url(rdv_id)
    "#{rdv_sp_host_url}/users/rdvs/#{rdv_id}"
  end

  def self.rdv_sp_rdv_agent_url(rdv_id)
    "#{rdv_sp_host_url}/agents/rdvs/#{rdv_id}"
  end

  def self.list_rdvs_url(rdv_ids)
    params = rdv_ids.map { |id| "id[]=#{id}" }.join('&')
    "#{rdv_sp_host_url}/api/v1/rdvs?#{params}"
  end

  def create_rdv_plan(dossier:, first_name:, last_name:, email:, dossier_url:, return_url:)
    refresh_token_if_expired!

    rdv = {
      user: {
        first_name:,
        last_name:,
        email:
      },
      return_url:,
      dossier_url:
    }

    response = Typhoeus.post(
      self.class.create_rdv_plan_url,
      body: rdv.to_json,
      headers:
    )

    if response.success?
      # {
      #   "rdv_plan":
      #   {
      #     "id":10,
      #     "created_at":"2025-01-23 15:15:20 +0100",
      #     "rdv":null,
      #     "updated_at":"2025-01-23 15:15:20 +0100",
      #     "url":"https://demo.rdv.anct.gouv.fr/agents/rdv_plans/10",
      #     "user_id":6425
      #   }
      # }

      Success(Rdv.create!(
        instructeur: @rdv_connection.instructeur,
        dossier: dossier,
        rdv_plan_external_id: JSON.parse(response.body)["rdv_plan"]["id"]
      ))
    else
      error_message = "RdvService#create_rdv_plan failed #{response.code} #{response.body}"
      Rails.logger.error(error_message)
      Sentry.capture_message(error_message)
      Failure("Une erreur est survenue")
    end
  end

  def update_pending_rdv_plan!(dossier:)
    # To be replaced by the webhook

    refresh_token_if_expired!

    pending_rdv_plan = dossier.rdvs.order(created_at: :desc).where(rdv_external_id: nil).first

    return if pending_rdv_plan.nil?

    response = Typhoeus.get(
      self.class.update_pending_rdv_plan_url(pending_rdv_plan.rdv_plan_external_id),
      headers:
    )

    return if !response.success?

    parsed_body = JSON.parse(response.body)

    # {
    #   "rdv_plan":
    #   {
    #     "id":10,
    #     "created_at":"2025-01-23 15:15:20 +0100",
    #     "rdv":{
    #       "id"=>10093,
    #       "status"=>"unknown",
    #       "starts_at"=>"2025-02-11 10:30:00 +0100",
    #       "location_type"=>"phone"
    #     },
    #     "updated_at":"2025-01-23 15:15:20 +0100",
    #     "url":"https://demo.rdv.anct.gouv.fr/agents/rdv_plans/10",
    #     "user_id":6425
    #   }
    # }

    if parsed_body["rdv_plan"]["rdv"].present?
      pending_rdv_plan.update!(
        rdv_external_id: parsed_body["rdv_plan"]["rdv"]["id"],
        starts_at: Time.zone.parse(parsed_body["rdv_plan"]["rdv"]["starts_at"]),
        location_type: parsed_body["rdv_plan"]["rdv"]["location_type"]
      )
    end
  end

  def list_rdvs(rdv_ids)
    return [] if rdv_ids.blank?

    refresh_token_if_expired!

    response = Typhoeus.get(
      self.class.list_rdvs_url(rdv_ids),
      headers:
    )

    if !response.success?
      error_message = "RdvService#list_rdvs failed #{response.code} #{response.body}"
      Rails.logger.error(error_message)
      Sentry.capture_message(error_message)
      return nil
    end

    parsed_body = JSON.parse(response.body)

    parsed_body["rdvs"]
  end

  def refresh_token_if_expired!
    return if !@rdv_connection.expired?

    client = OAuth2::Client.new(
      ENV['RDV_SERVICE_PUBLIC_OAUTH_APP_ID'],
      ENV['RDV_SERVICE_PUBLIC_OAUTH_APP_SECRET'],
      site: ENV["RDV_SERVICE_PUBLIC_URL"]
    )

    old_token = OAuth2::AccessToken.new(
      client,
      @rdv_connection.access_token,
      refresh_token: @rdv_connection.refresh_token
    )

    new_token = old_token.refresh!

    @rdv_connection.update!(
      access_token: new_token.token,
      refresh_token: new_token.refresh_token,
      expires_at: Time.zone.at(new_token.expires_at)
    )
  rescue OAuth2::Error => e
    # Destroy the connection so the user needs to re-authorize
    @rdv_connection.destroy!

    raise e
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@rdv_connection.access_token}"
    }
  end
end
