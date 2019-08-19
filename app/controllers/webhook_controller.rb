class WebhookController < ActionController::Base
  before_action :verify_signature!, only: :helpscout

  def helpscout
    email = params[:customer][:email].downcase
    user = User.find_by(email: email)
    instructeur = Instructeur.find_by(email: email)
    administrateur = Administrateur.find_by(email: email)
    html = []

    if user
      url = manager_user_url(user)
      html << link_to_manager(user, url)
    end

    if instructeur
      url = manager_instructeur_url(instructeur)
      html << link_to_manager(instructeur, url)
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

  private

  def link_to_manager(model, url)
    "<a target='_blank' href='#{url}' rel='noopener'>#{model.model_name.human}##{model.id}</a>"
  end

  def verify_signature!
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
