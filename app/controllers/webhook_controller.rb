class WebhookController < ActionController::Base
  before_action :verify_helpscout_signature!, only: [:helpscout, :helpscout_support_dev]
  skip_before_action :verify_authenticity_token

  def sendinblue
    if Rails.application.secrets.dig(:mattermost, :send_in_blue_outage_webhook_url).present?
      send_mattermost_notification(
        Rails.application.secrets.dig(:mattermost, :send_in_blue_outage_webhook_url),
        message_to_mattermost_send_in_blue_channel
      )
    end
  end

  def helpscout_support_dev
    if tagged_dev? && status_active? && Rails.application.secrets.dig(:mattermost, :support_webhook_url).present?
      send_mattermost_notification(
        Rails.application.secrets.dig(:mattermost, :support_webhook_url),
        message_to_mattermost_support_channel
      )
    end

    head :no_content
  end

  def helpscout
    email = params[:customer][:email].downcase
    user = User.find_by(email: email)

    if user.nil?
      head :not_found

    else
      instructeur = user.instructeur
      administrateur = user.administrateur

      url = manager_user_url(user)
      html = [link_to_manager(user, url)]

      if instructeur
        url = manager_instructeur_url(instructeur)
        html << link_to_manager(instructeur, url)
      end

      if administrateur
        url = manager_administrateur_url(administrateur)
        html << link_to_manager(administrateur, url)
      end

      html << email_link_to_manager(user)

      render json: { html: html.join('<br>') }
    end
  end

  private

  def send_mattermost_notification(url, text)
    Net::HTTP.post(
      URI.parse(url),
      { "text": text }.to_json,
     "Content-Type" => "application/json"
    )
  end

  def message_to_mattermost_support_channel
    %Q(
Nouveau bug taggué #dev : https://secure.helpscout.net/conversation/#{params["id"]}/#{params["number"]}?folderId=#{params["folderId"]}

> #{params['webhook']['preview']}

**personnes impliquées** : #{threads.map { |thread| thread['createdBy']['email'] }.uniq.join(", ")}
**utilisateur en attente depuis** : #{params['customerWaitingSince']['friendly']})
  end

  def message_to_mattermost_send_in_blue_channel
    %Q{Incident sur SIB : #{params['title']}.
Etat de SIB: #{params['current_status']}
L'Incident a commencé à #{params['datetime_start']} et est p-e terminé a #{params['datetime_resolve']}
les composant suivants sont affectés : #{params["components"].map { _1['name'] }.join(", ")}}
  end

  def threads
    params['_embedded']['threads']
  end

  def tagged_dev?
    params["tags"].any? { _1['tag'].include?('dev') }
  end

  def status_active?
    params["status"] == 'active'
  end

  def link_to_manager(model, url)
    "<a target='_blank' href='#{url}' rel='noopener'>#{model.model_name.human}##{model.id}</a>"
  end

  def email_link_to_manager(user)
    url = emails_manager_user_url(user)
    "<a target='_blank' href='#{url}' rel='noopener'>Emails##{user.id}</a>"
  end

  def verify_helpscout_signature!
    if generate_body_signature(request.body.read) != request.headers['X-Helpscout-Signature']
      request_http_token_authentication
    end
  end

  def generate_body_signature(body)
    Base64.strict_encode64(OpenSSL::HMAC.digest('sha1',
      Rails.application.secrets.helpscout[:webhook_secret],
      body))
  end
end
