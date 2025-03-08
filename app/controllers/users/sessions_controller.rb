# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include ProcedureContextConcern
  include TrustedDeviceConcern
  include ActionView::Helpers::DateHelper

  layout 'login', only: [:new, :create]

  before_action :redirect_to_agent_connect_if_mandatory, only: [:create]
  before_action :restore_procedure_context, only: [:new, :create]
  skip_before_action :redirect_if_untrusted, only: [:reset_link_sent]
  # POST /resource/sign_in
  def create
    user = User.find_by(email: params[:user][:email])

    if user&.valid_password?(params[:user][:password])
      user.update(loged_in_with_france_connect: nil)
      user.update_preferred_domain(Current.host) if helpers.switch_domain_enabled?(request)
    end

    super
    if current_account.count > 1
      flash[:notice] = t("devise.sessions.signed_in_multiple_profile", roles: current_account.keys.map { |role| t("layouts.#{role}") }.to_sentence)
    end
  end

  def reset_link_sent
    if send_login_token_or_bufferize(current_instructeur)
      flash[:notice] = "Nous venons de vous renvoyer un nouveau lien de connexion sécurisée à #{Current.application_name}"
    end

    signed_email = message_verifier.generate(current_instructeur.email, purpose: :reset_link, expires_in: 1.hour)
    redirect_to link_sent_path(email: signed_email)
  end

  def link_sent
    email = message_verifier.verify(params[:email], purpose: :reset_link) rescue nil

    if StrictEmailValidator::REGEXP.match?(email)
      @email = email
    else
      redirect_to root_path
    end
  end

  # DELETE /resource/sign_out
  def destroy
    if user_signed_in?
      connected_with_france_connect = current_user.loged_in_with_france_connect
      agent_connect_id_token = current_user&.instructeur&.agent_connect_id_token

      current_user.update(loged_in_with_france_connect: nil)
      current_user&.instructeur&.update(agent_connect_id_token: nil)

      sign_out :user

      if connected_with_france_connect == User.loged_in_with_france_connects.fetch(:particulier)
        return redirect_to FRANCE_CONNECT[:particulier][:logout_endpoint], allow_other_host: true
      end

      if agent_connect_id_token.present?
        return redirect_to AgentConnectService.logout_url(agent_connect_id_token, host_with_port: request.host_with_port),
          allow_other_host: true
      end
    end

    respond_to_on_destroy
  end

  def no_procedure
    clear_stored_location_for(:user)
    redirect_to new_user_session_path
  end

  def sign_in_by_link
    instructeur = Instructeur.find(params[:id])
    trusted_device_token = instructeur
      .trusted_device_tokens
      .find_by(token: params[:jeton])

    if trusted_device_token.nil?
      flash[:alert] = 'Votre lien est invalide.'

      redirect_to root_path
    elsif trusted_device_token.token_valid?
      trust_device(trusted_device_token.created_at)

      period = ((trusted_device_token.created_at + TRUSTED_DEVICE_PERIOD) - Time.zone.now).to_i / ActiveSupport::Duration::SECONDS_PER_DAY

      flash.notice = "Merci d’avoir confirmé votre connexion. Votre navigateur est maintenant authentifié pour #{period} jours."

      # redirect to procedure'url if stored by store_location_for(:user) in dossiers_controller
      # redirect to root_path otherwise

      if instructeur_signed_in?
        current_user.update!(email_verified_at: Time.zone.now)

        redirect_to after_sign_in_path_for(:user)
      else
        redirect_to new_user_session_path
      end
    else
      flash[:alert] = 'Votre lien est expiré, un nouveau vient de vous être envoyé.'

      send_login_token_or_bufferize(instructeur)
      redirect_to link_sent_path(email: instructeur.email)
    end
  end

  # Pro connect callback
  def logout
    redirect_to root_path, notice: I18n.t('devise.sessions.signed_out')
  end

  def redirect_to_agent_connect_if_mandatory
    return if !AgentConnectService.enabled?

    return if !AgentConnectService.email_domain_is_in_mandatory_list?(params[:user][:email])

    flash[:alert] = "La connexion des agents passe à présent systématiquement par ProConnect"
    redirect_to pro_connect_path(force_proconnect: true)
  end
end
