# frozen_string_literal: true

class FranceConnect::ParticulierController < ApplicationController
  before_action :redirect_to_login_if_fc_aborted, only: [:callback]
  before_action :securely_retrieve_fci, only: [:merge, :merge_with_existing_account, :merge_with_new_account, :resend_and_renew_merge_confirmation, :associate_user]
  before_action :securely_retrieve_fci_from_email_merge_token, only: [:mail_merge_with_existing_account]
  before_action :set_user_by_confirmation_token, only: [:resend_confirmation, :post_resend_confirmation, :confirm_email, :connect_france_connect_particulier_redirect]

  def login
    if FranceConnectService.enabled?
      redirect_to FranceConnectService.authorization_uri, allow_other_host: true
    else
      redirect_to new_user_session_path
    end
  end

  def callback
    fci = FranceConnectService.find_or_retrieve_france_connect_information(params[:code])

    if fci.user.nil?
      preexisting_unlinked_user = User.find_by(email: sanitize(fci.email_france_connect))

      if preexisting_unlinked_user.nil?
        merge_token = fci.create_merge_token!
        render :choose_email, locals: { france_connect_email: fci.email_france_connect, merge_token: }

      elsif !preexisting_unlinked_user.can_france_connect?
        fci.destroy
        redirect_to new_user_session_path, alert: t('errors.messages.france_connect.forbidden_html', reset_link: new_user_password_path)
      else
        merge_token = fci.create_merge_token!
        redirect_to france_connect_particulier_merge_path(merge_token)
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

  def associate_user
    email = use_fc_email? ? @fci.email_france_connect : params[:alternative_email]
    @fci.associate_user!(email)
    user = @fci.user

    @fci.delete_merge_token!
    sign_only(user)

    destination_path = destination_path(user)
    render :confirmation_sent, locals: { email:, destination_path: }
  rescue ActiveRecord::RecordInvalid => e
    if e.record.errors.where(:email, :taken)
      redirect_to new_user_session_path, alert: t('errors.messages.france_connect.email_taken', reset_link: new_user_password_path)
    else
      redirect_to new_user_session_path, alert: t('errors.messages.france_connect.unknown_error')
    end
  end

  def merge
  end

  def merge_with_existing_account
    user = User.find_by(email: sanitized_email_params)

    if user.present? && user.valid_for_authentication? { user.valid_password?(password_params) }
      if !user.can_france_connect?
        flash.alert = t('errors.messages.france_connect.forbidden_html', reset_link: new_user_password_path)

        redirect_to root_path
      else
        @fci.update(user: user)
        @fci.delete_merge_token!
        @fci.delete_email_merge_token!

        flash.notice = t('france_connect.particulier.flash.connection_done', application_name: Current.application_name)
        connect_france_connect_particulier(user)
      end
    else
      flash.alert = t('france_connect.particulier.flash.invalid_password')
    end
  end

  def mail_merge_with_existing_account
    user = User.find_by(email: sanitize(@fci.email_france_connect.downcase))
    if user.can_france_connect?
      @fci.update(user: user)
      @fci.delete_merge_token!
      user.update(email_verified_at: Time.zone.now)
      flash.notice = t('france_connect.particulier.flash.connection_done', application_name: Current.application_name)
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
      @fci.send_custom_confirmation_instructions(@fci.user)
      flash.notice = t('france_connect.particulier.flash.connection_done_verify_email', application_name: Current.application_name)
      connect_france_connect_particulier(@fci.user)
    else
      @email = sanitized_email_params
      @merge_token = merge_token_params
    end
  end

  def resend_and_renew_merge_confirmation
    @fci.create_email_merge_token!
    UserMailer.france_connect_merge_confirmation(
      @fci.email_france_connect,
      @fci.email_merge_token,
      @fci.email_merge_token_created_at
    )
      .deliver_later

    merge_token = @fci.create_merge_token!
    redirect_to france_connect_particulier_merge_path(merge_token),
                notice: t('france_connect.particulier.flash.confirmation_mail_sent')
  end

  def confirm_email
    if @user.confirmation_sent_at && 2.days.ago < @user.confirmation_sent_at
      @user.update(email_verified_at: Time.zone.now, confirmation_token: nil)
      @user.after_confirmation
      redirect_to stored_location_for(@user) || root_path(@user), notice: 'Votre email est bien vérifié'
    else
      redirect_to france_connect_resend_confirmation_path(token: @user.confirmation_token), alert: "Lien de confirmation expiré. Un nouveau lien de confirmation a été envoyé."
    end
  end

  def resend_confirmation
    if @user.email_verified_at
      redirect_to root_path, alert: 'Email déjà confirmé.'
    end
  end

  def post_resend_confirmation
    if !@user.email_verified_at
      fci = FranceConnectInformation.find_by(user: @user)
      fci.send_custom_confirmation_instructions(@user)
      redirect_to root_path(@user), notice: "Un nouveau lien de confirmation vous a été envoyé par mail."
    else
      redirect_to root_path(@user), alert: "Adresse email non trouvée ou déjà confirmée."
    end
  end

  private

  def set_user_by_confirmation_token
    @user = User.find_by(confirmation_token: params[:token])

    if @user.nil?
      redirect_to root_path, alert: 'Utilisateur non trouvé' and return
    end

    if user_signed_in? && current_user != @user
      sign_out current_user
      redirect_to new_user_session_path, alert: "Veuillez vous connecter avec le compte associé à ce lien de confirmation."
    end
  end

  def use_fc_email? = cast_bool(params[:use_france_connect_email])

  def sign_only(user)
    sign_out(user) if user_signed_in?
    sign_in(user)
  end

  def destination_path(user) = stored_location_for(user) || root_path(user)

  def securely_retrieve_fci_from_email_merge_token
    @fci = FranceConnectInformation.find_by(email_merge_token: email_merge_token_params)

    if @fci.nil? || !@fci.valid_for_email_merge?
      flash.alert = t('france_connect.particulier.flash.merger_token_expired', application_name: Current.application_name)

      redirect_to root_path
    else
      @fci.delete_email_merge_token!
    end
  end

  def securely_retrieve_fci
    @fci = FranceConnectInformation.find_by(merge_token: merge_token_params)

    if @fci.nil? || !@fci.valid_for_merge?
      flash.alert = t('france_connect.particulier.flash.merger_token_expired', application_name: Current.application_name)

      redirect_to root_path
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

    redirect_to stored_location_for(current_user) || root_path(current_user)
  end

  def redirect_france_connect_error_connection
    flash.alert = t('errors.messages.france_connect.connexion')
    redirect_to(new_user_session_path)
  end

  def merge_token_params
    params[:merge_token]
  end

  def email_merge_token_params
    params[:email_merge_token]
  end

  def password_params
    params[:password]
  end

  def sanitized_email_params
    sanitize(params[:email])
  end

  def sanitize(string)
    string&.gsub(/[[:space:]]/, ' ')&.strip&.downcase
  end
end
