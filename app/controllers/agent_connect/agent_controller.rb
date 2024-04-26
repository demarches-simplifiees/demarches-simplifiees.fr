# doc: https://github.com/france-connect/Documentation-AgentConnect
class AgentConnect::AgentController < ApplicationController
  before_action :redirect_to_login_if_fc_aborted, only: [:callback]
  before_action :check_state, only: [:callback]

  STATE_COOKIE_NAME = :agentConnect_state
  NONCE_COOKIE_NAME = :agentConnect_nonce

  def index
  end

  def login
    uri, state, nonce = AgentConnectService.authorization_uri

    cookies.encrypted[STATE_COOKIE_NAME] = state
    cookies.encrypted[NONCE_COOKIE_NAME] = nonce

    redirect_to uri, allow_other_host: true
  end

  def callback
    user_info = AgentConnectService.user_info(params[:code], cookies.encrypted[NONCE_COOKIE_NAME])
    cookies.encrypted[NONCE_COOKIE_NAME] = nil

    instructeur = Instructeur.find_by(agent_connect_id: user_info['sub'])

    if instructeur.nil?
      instructeur = Instructeur.find_by(users: { email: santized_email(user_info) })
      instructeur&.update(agent_connect_id: user_info['sub'])
    end

    if instructeur.nil?
      user = User.create_or_promote_to_instructeur(santized_email(user_info), Devise.friendly_token[0, 20])
      instructeur = user.instructeur
      instructeur.update(agent_connect_id: user_info['sub'])
    end

    aci = AgentConnectInformation.find_or_initialize_by(instructeur:)
    aci.update(user_info.slice('given_name', 'usual_name', 'email', 'sub', 'siret', 'organizational_unit', 'belonging_population', 'phone'))

    sign_in(:user, instructeur.user)

    redirect_to instructeur_procedures_path

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
      cookies.encrypted[STATE_COOKIE_NAME] = nil
    end
  end
end
