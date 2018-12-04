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
    sender = params['From']
    body = params['Text-part'] || params['Html-part']
    dossier_id = params['CustomID']
    dossier = Dossier.find_by(id: dossier_id)

    Rails.logger.info("Inbound email: received Mailjet webhook from '#{sender}' (spam score: #{params['SpamAssassinScore']}")

    if !sender
      return inbound_email_error("Could not find sender for inbound email (#{params}}", bounce_to: nil)
    end

    if dossier.blank?
      return inbound_email_error("Could not find a dossier for id `#{dossier_id}`", bounce_to: sender)
    end

    if sender != dossier.user.email
      return inbound_email_error("Could not post the inbound email: inbound sender `#{sender}` is different from the dossier owner `#{dossier.user.email}`", bounce_to: sender)
    end

    if body.blank?
      return inbound_email_error("Could not find the message body", bounce_to: sender)
    end

    comment = CommentaireService.create(dossier.user, dossier, body: body)
    # TODO: handle attachements

    if !comment.save
      return inbound_email_error("Error while saving an inbound comment (#{comment.errors.full_messages})", bounce_to: sender)
    end

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

  def inbound_email_error(error_message, bounce_to:)
    Raven.capture_message("Inbound email error: #{error_message}")
    # Tell Mailjet that we got an error, but that the message was processed successfully
    head :no_content
  end
end
