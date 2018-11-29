class WebhookController < ActionController::Base
  before_action :verify_helpscout_signature!, only: :helpscout

  def helpscout
    email = params[:customer][:email]
    user = User.find_by(email: email)
    gestionnaire = Gestionnaire.find_by(email: email)
    administrateur = Administrateur.find_by(email: email)
    html = []

    if user
      url = manager_user_url(user)
      html << link_to_manager(user, url)
    end

    if gestionnaire
      url = manager_gestionnaire_url(gestionnaire)
      html << link_to_manager(gestionnaire, url)
    end

    if administrateur
      url = manager_administrateur_url(administrateur)
      html << link_to_manager(administrateur, url)
    end

    if html.empty?
      head :not_found
    else
      render json: { html: html.join('<br>') }
    end
  end

  def mailjet
    puts "Received Mailjet webhook with params #{params}"
    head :ok
  end

  private

  def link_to_manager(model, url)
    "<a target='_blank' href='#{url}'>#{model.model_name.human}##{model.id}</a>"
  end

  def verify_helpscout_signature!
    if generate_helpscout_body_signature(request.body.read) != request.headers['X-Helpscout-Signature']
      request_http_token_authentication
    end
  end

  def generate_helpscout_body_signature(body)
    Base64.strict_encode64(OpenSSL::HMAC.digest('sha1',
      Rails.application.secrets.helpscout[:webhook_secret],
      body))
  end
end
