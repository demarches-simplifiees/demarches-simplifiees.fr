# doc: https://github.com/france-connect/Documentation-AgentConnect
class AgentConnect::AgentController < ApplicationController
  before_action :redirect_to_login_if_fc_aborted, only: [:callback]

  def index
  end

  def login
    redirect_to AgentConnectService.authorization_uri
  end

  def callback
    user_info = AgentConnectService.user_info(params[:code])

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
end
