# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include ProcedureContextConcern
  include TrustedDeviceConcern
  include ActionView::Helpers::DateHelper

  layout 'login', only: [:new, :create]

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
      flash[:notice] = t("devise.sessions.signed_in_multiple_profile", roles: current_account.keys.map { |role| t("layouts.#{role}") }.join(', '))
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

      case connected_with_france_connect
      when User.loged_in_with_france_connects.fetch(:particulier)
        redirect_to FRANCE_CONNECT[:particulier][:logout_endpoint], allow_other_host: true
        return
      when User.loged_in_with_france_connects.fetch(:sipf), User.loged_in_with_france_connects.fetch(:tatou)
        params = { redirect_uri: root_url }
        redirect_to "#{Rails.application.secrets[connected_with_france_connect][:logout_endpoint]}?#{params.to_query}", allow_other_host: true
        return
        # when User.loged_in_with_france_connects.fetch(:microsoft)
        #   params = { post_logout_redirect_uri: root_url }
        #   redirect_to "#{Rails.application.secrets.microsoft[:logout_endpoint]}?#{params.to_query}"
        #   return
      end
      if agent_connect_id_token.present?
        return redirect_to build_agent_connect_logout_url(agent_connect_id_token), allow_other_host: true
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

  # agent connect callback
  def logout
    redirect_to root_path, notice: I18n.t('devise.sessions.signed_out')
  end

  private

  def build_agent_connect_logout_url(id_token)
    h = { id_token_hint: id_token, post_logout_redirect_uri: logout_url }
    "#{AGENT_CONNECT[:end_session_endpoint]}?#{h.to_query}"
  end
end
