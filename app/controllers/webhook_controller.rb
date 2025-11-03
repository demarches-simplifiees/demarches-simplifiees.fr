# frozen_string_literal: true

class WebhookController < ActionController::Base
  before_action :verify_crisp_signature!, only: [:crisp]
  skip_before_action :verify_authenticity_token

  def sendinblue
    webhook_url = ENV["SEND_IN_BLUE_OUTAGE_WEBHOOK_URL"]
    if webhook_url.present?
      send_mattermost_notification(
        webhook_url,
        message_to_mattermost_send_in_blue_channel
      )
    end
  end

  def crisp
    # Note: always respond with 200 or webhooks will be suspended.
    Crisp::WebhookProcessor.new(params).process
    head :ok
  end

  private

  def send_mattermost_notification(url, text)
    Net::HTTP.post(
      URI.parse(url),
      { "text": text }.to_json,
     "Content-Type" => "application/json"
    )
  end

  def message_to_mattermost_send_in_blue_channel
    %Q{Incident sur SIB : #{params['title']}.
Etat de SIB: #{params['current_status']}
L'Incident a commencé à #{params['datetime_start']} et est p-e terminé a #{params['datetime_resolve']}
les composant suivants sont affectés : #{params["components"].map { _1['name'] }.join(", ")}}
  end

  def link_to_manager(model, url)
    "<a target='_blank' href='#{url}' rel='noopener'>#{model.model_name.human}##{model.id}</a>"
  end

  def email_link_to_manager(user)
    url = emails_manager_user_url(user)
    "<a target='_blank' href='#{url}' rel='noopener'>Emails##{user.id}</a>"
  end

  def verify_crisp_signature!
    timestamp = request.headers['X-Crisp-Request-Timestamp']
    signature = request.headers['X-Crisp-Signature']

    body = request.body.read
    concatenated_string = "[#{timestamp};#{body}]"

    expected_signature = OpenSSL::HMAC.hexdigest('sha256',
      ENV.fetch("CRISP_WEBHOOK_SECRET"),
      concatenated_string)

    head :bad_request unless signature == expected_signature
  end
end
