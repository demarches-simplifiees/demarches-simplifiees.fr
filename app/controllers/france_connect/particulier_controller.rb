class FranceConnect::ParticulierController < ApplicationController
  before_action :redirect_to_login_if_fc_aborted, only: [:callback]
  before_action :securely_retrieve_fci, only: [:merge, :merge_with_existing_account, :merge_with_new_account]

  def login
    if FranceConnectService.enabled?
      redirect_to FranceConnectService.authorization_uri
    else
      redirect_to new_user_session_path
    end
  end

  def callback
    fci = FranceConnectService.find_or_retrieve_france_connect_information(params[:code])

    if fci.user.nil?
      preexisting_unlinked_user = User.find_by(email: fci.email_france_connect.downcase)

      if preexisting_unlinked_user.nil?
        fci.associate_user!(fci.email_france_connect)
        connect_france_connect_particulier(fci.user)
      else
        redirect_to france_connect_particulier_merge_path(fci.create_merge_token!)
      end
    else
      user = fci.user

      if user.can_france_connect?
        fci.update(updated_at: Time.zone.now)
        connect_france_connect_particulier(user)
      else
        fci.destroy
        redirect_to new_user_session_path, alert: t('errors.messages.france_connect.forbidden_html', reset_link: new_user_password_path)
      end
    end

  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_france_connect_error_connection
  end

  def merge
  end

  def merge_with_existing_account
    user = User.find_by(email: sanitized_email_params)

    if user.present? && user.valid_for_authentication? { user.valid_password?(password_params) }
      if !user.can_france_connect?
        flash.alert = "#{user.email} ne peut utiliser FranceConnect"

        render js: ajax_redirect(root_path)
      else
        @fci.update(user: user)
        @fci.delete_merge_token!

        flash.notice = "Les comptes FranceConnect et #{APPLICATION_NAME} sont à présent fusionnés"
        connect_france_connect_particulier(user)
      end
    else
      flash.alert = 'Mauvais mot de passe'

      render js: helpers.render_flash
    end
  end

  def merge_with_new_account
    user = User.find_by(email: sanitized_email_params)

    if user.nil?
      @fci.associate_user!(sanitized_email_params)
      @fci.delete_merge_token!

      flash.notice = "Les comptes FranceConnect et #{APPLICATION_NAME} sont à présent fusionnés"
      connect_france_connect_particulier(@fci.user)
    else
      @email = sanitized_email_params
      @merge_token = merge_token_params
    end
  end

  private

  def securely_retrieve_fci
    @fci = FranceConnectInformation.find_by(merge_token: merge_token_params)

    if @fci.nil? || !@fci.valid_for_merge?
      flash.alert = 'Votre compte FranceConnect a expiré, veuillez recommencer.'

      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render js: ajax_redirect(root_path) }
      end
    end
  end

  def redirect_to_login_if_fc_aborted
    if params[:code].blank?
      redirect_to new_user_session_path
    end
  end

  def connect_france_connect_particulier(user)
    if user_signed_in?
      sign_out :user
    end

    sign_in user

    user.update_attribute('loged_in_with_france_connect', User.loged_in_with_france_connects.fetch(:particulier))

    redirection_location = stored_location_for(current_user) || root_path(current_user)

    respond_to do |format|
      format.html { redirect_to redirection_location }
      format.js { render js: ajax_redirect(root_path) }
    end
  end

  def redirect_france_connect_error_connection
    flash.alert = t('errors.messages.france_connect.connexion')
    redirect_to(new_user_session_path)
  end

  def merge_token_params
    params[:merge_token]
  end

  def password_params
    params[:password]
  end

  def sanitized_email_params
    params[:email]&.gsub(/[[:space:]]/, ' ')&.strip&.downcase
  end
end
