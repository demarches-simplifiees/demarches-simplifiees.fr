# frozen_string_literal: true

# doc: https://github.com/france-connect/Documentation-AgentConnect
class AgentConnect::AgentController < ApplicationController
  before_action :redirect_to_login_if_fc_aborted, only: [:callback]
  before_action :check_state, only: [:callback]

  MON_COMPTE_PRO_IDP_ID = "71144ab3-ee1a-4401-b7b3-79b44f7daeeb"

  STATE_COOKIE_NAME = :agentConnect_state
  NONCE_COOKIE_NAME = :agentConnect_nonce

  AC_ID_TOKEN_COOKIE_NAME = :agentConnect_id_token
  REDIRECT_TO_AC_LOGIN_COOKIE_NAME = :redirect_to_ac_login

  def index
  end

  def login
    uri, state, nonce = AgentConnectService.authorization_uri

    cookies.encrypted[STATE_COOKIE_NAME] = { value: state, secure: Rails.env.production?, httponly: true }
    cookies.encrypted[NONCE_COOKIE_NAME] = { value: nonce, secure: Rails.env.production?, httponly: true }

    redirect_to uri, allow_other_host: true
  end

  def callback
    user_info, id_token, amr = AgentConnectService.user_info(params[:code], cookies.encrypted[NONCE_COOKIE_NAME])
    cookies.delete NONCE_COOKIE_NAME

    if user_info['idp_id'] == MON_COMPTE_PRO_IDP_ID &&
        !amr.include?('mfa') &&
        Flipper.enabled?(:agent_connect_2fa, Struct.new(:flipper_id).new(flipper_id: user_info['email']))
      # we need the id_token to disconnect the agent connect session later.
      # we cannot store it in the instructeur model because the user is not yet created
      # so we store it in a encrypted cookie
      cookies.encrypted[AC_ID_TOKEN_COOKIE_NAME] = id_token
      return redirect_to agent_connect_explanation_2fa_path
    end

    instructeur = Instructeur.find_by(users: { email: santized_email(user_info) })

    if instructeur.nil?
      user = User.create_or_promote_to_instructeur(santized_email(user_info), Devise.friendly_token[0, 20], agent_connect: true)
      instructeur = user.instructeur
    end

    instructeur.update!(agent_connect_id_token: id_token)
    instructeur.user.update!(email_verified_at: Time.zone.now)

    aci = AgentConnectInformation.find_or_initialize_by(instructeur:, sub: user_info['sub'])
    aci.update(user_info.slice('given_name', 'usual_name', 'email', 'sub', 'siret', 'organizational_unit', 'belonging_population', 'phone').merge(amr:))

    sign_in(:user, instructeur.user)

    redirect_to instructeur_procedures_path

  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_france_connect_error_connection
  end

  def explanation_2fa
  end

  # Special callback from MonComptePro juste after 2FA configuration
  # then:
  # - the current user is disconnected from the AgentConnect session by redirecting to the AgentConnect logout endpoint
  # - the user is redirected to User::SessionsController#logout by agent connect (no choice)
  # - the cookie redirect_to_ac_login is detected and the controller redirects to the relogin_after_2fa_config page
  # - finally, the user clicks on the button to reconnect to the AgentConnect session
  def logout_from_mcp
    sign_out(:user) if user_signed_in?

    id_token = cookies.encrypted[AC_ID_TOKEN_COOKIE_NAME]
    cookies.delete(AC_ID_TOKEN_COOKIE_NAME)

    return redirect_to root_path if id_token.blank?

    cookies.encrypted[REDIRECT_TO_AC_LOGIN_COOKIE_NAME] = true

    redirect_to AgentConnectService.logout_url(id_token, host_with_port: request.host_with_port), allow_other_host: true
  end

  def relogin_after_2fa_config
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
