class FranceConnect::ParticulierController < ApplicationController
  before_action :redirect_to_login_if_fc_aborted, only: [:callback]
  before_action :securely_retrieve_fci, only: [:merge, :merge_with_existing_account, :merge_with_new_account, :mail_merge_with_existing_account, :resend_and_renew_merge_confirmation]

  def login
    if FranceConnectService.enabled?
      redirect_to FranceConnectService.new(**credentials).authorization_uri
    else
      redirect_to new_user_session_path
    end
  end

  def callback
    fcs = FranceConnectService.new(code: callback_params[:code], **credentials)
    fci = fcs.find_or_retrieve_france_connect_information

    if fci.user.nil?
      preexisting_unlinked_user = User.find_by(email: fci.email_france_connect.downcase)

      if preexisting_unlinked_user.nil?
        fci.associate_user!(fci.email_france_connect)
        connect_france_connect_particulier(fci.user)
      elsif !preexisting_unlinked_user.can_france_connect?
        fci.destroy
        redirect_to new_user_session_path, alert: t('errors.messages.france_connect.forbidden_html', reset_link: new_user_password_path)
      else
        merge_token = fci.create_merge_token!
        redirect_to france_connect_particulier_merge_path(merge_token)
      end
    elsif fci.user.can_france_connect?
      fci.update(updated_at: Time.zone.now)
      connect_france_connect_particulier(fci.user)
    else # same behaviour as redirect nicely with message when instructeur/administrateur
      fci.destroy
      redirect_to new_user_session_path, alert: t('errors.messages.france_connect.forbidden_html', reset_link: new_user_password_path)
    end
  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_to new_user_session_path, alert: t('errors.messages.france_connect.connexion')
  end

  def merge
  end

  def merge_with_existing_account
    user = User.find_by(email: sanitized_email_params)

    if user.present? && user.valid_for_authentication? { user.valid_password?(password_params) }
      if !user.can_france_connect?
        flash.alert = t('errors.messages.france_connect.forbidden_html', reset_link: new_user_password_path)

        render js: ajax_redirect(root_path)
      else
        @fci.update(user: user)
        @fci.delete_merge_token!

        flash.notice = t('france_connect.particulier.flash.connection_done', application_name: APPLICATION_NAME)
        connect_france_connect_particulier(user)
      end
    else
      flash.alert = t('france_connect.particulier.flash.invalid_password')

      render js: helpers.render_flash
    end
  end

  def mail_merge_with_existing_account
    user = User.find_by(email: @fci.email_france_connect.downcase)
    if user.can_france_connect?
      @fci.update(user: user)
      @fci.delete_merge_token!

      flash.notice = t('france_connect.particulier.flash.connection_done', application_name: APPLICATION_NAME)
      connect_france_connect_particulier(user)
    else # same behaviour as redirect nicely with message when instructeur/administrateur
      @fci.destroy
      redirect_to new_user_session_path, alert: t('errors.messages.france_connect.forbidden_html', reset_link: new_user_password_path)
    end
  end

  def merge_with_new_account
    user = User.find_by(email: sanitized_email_params)

    if user.nil?
      @fci.associate_user!(sanitized_email_params)
      @fci.delete_merge_token!

      flash.notice = t('france_connect.particulier.flash.connection_done', application_name: APPLICATION_NAME)
      connect_france_connect_particulier(@fci.user)
    else
      @email = sanitized_email_params
      @merge_token = merge_token_params
    end
  end

  def resend_and_renew_merge_confirmation
    merge_token = @fci.create_merge_token!
    UserMailer.france_connect_merge_confirmation(@fci.email_france_connect, merge_token, @fci.merge_token_created_at).deliver_later
    redirect_to france_connect_particulier_merge_path(merge_token),
                notice: t('france_connect.particulier.flash.confirmation_mail_sent')
  end

  private

  def securely_retrieve_fci
    @fci = FranceConnectInformation.find_by(merge_token: merge_token_params)

    if @fci.nil? || !@fci.valid_for_merge?
      flash.alert = t('france_connect.particulier.flash.merger_token_expired', application_name: APPLICATION_NAME)

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

  def callback_params
    params.permit(:code, :state)
  end

  def procedure_path
    # Consume the stored procedure path and store it in another session key as
    # it will be used by both the credential service and the callback action.
    # By doing so, we avoid betting on the immutability of Devise internals.
    @procedure_path ||= session[:fc_user_procedure_path] ||= stored_location_for(:user)
  end

  def credentials
    FranceConnectCredentialsService.new.call(procedure_path)
  end

  def connect_france_connect_particulier(user)
    if user_signed_in?
      sign_out :user
    end

    sign_in user
    user.update_attribute(:loged_in_with_france_connect, User.loged_in_with_france_connect.fetch(:particulier))
    redirection_location = session.delete(:fc_user_procedure_path) || root_path(current_user)

    respond_to do |format|
      format.html { redirect_to redirection_location }
      format.js { render js: ajax_redirect(root_path) }
    end
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
