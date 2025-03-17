# frozen_string_literal: true

# doc: https://github.com/numerique-gouv/proconnect-documentation/tree/main
class ProConnectController < ApplicationController
  before_action :redirect_to_login_if_fc_aborted, only: [:callback]
  before_action :check_state, only: [:callback]

  STATE_COOKIE_NAME = :proConnect_state
  NONCE_COOKIE_NAME = :proConnect_nonce

  def index
  end

  def login
    uri, state, nonce = ProConnectService.authorization_uri

    cookies.encrypted[STATE_COOKIE_NAME] = { value: state, secure: Rails.env.production?, httponly: true }
    cookies.encrypted[NONCE_COOKIE_NAME] = { value: nonce, secure: Rails.env.production?, httponly: true }

    redirect_to uri, allow_other_host: true
  end

  def callback
    user_info, id_token, amr = ProConnectService.user_info(params[:code], cookies.encrypted[NONCE_COOKIE_NAME])
    cookies.delete NONCE_COOKIE_NAME

    instructeur = Instructeur.find_by(users: { email: santized_email(user_info) })

    if instructeur.nil?
      user = User.create_or_promote_to_instructeur(santized_email(user_info), Devise.friendly_token[0, 20], pro_connect: true)
      instructeur = user.instructeur
    end

    instructeur.update!(agent_connect_id_token: id_token)
    instructeur.user.update!(email_verified_at: Time.zone.now)

    aci = AgentConnectInformation.find_or_initialize_by(instructeur:, sub: user_info['sub'])
    aci.update(user_info.slice('given_name', 'usual_name', 'email', 'sub', 'siret', 'organizational_unit', 'belonging_population', 'phone').merge(amr:))

    sign_in(:user, instructeur.user)

    redirect_to stored_location_for(:user) || instructeur_procedures_path

  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_france_connect_error_connection
  end

  private

  def santized_email(user_info)
    user_info['email'].strip.downcase
  end

  def redirect_to_login_if_fc_aborted
    if params[:code].blank?
      redirect_to new_user_session_path
    end
  end

  def redirect_france_connect_error_connection
    flash.alert = t('errors.messages.france_connect.connexion')
    redirect_to(new_user_session_path)
  end

  def check_state
    if cookies.encrypted[STATE_COOKIE_NAME] != params[:state]
      flash.alert = t('errors.messages.france_connect.connexion')
      redirect_to(new_user_session_path)
    else
      cookies.delete STATE_COOKIE_NAME
    end
  end
end
