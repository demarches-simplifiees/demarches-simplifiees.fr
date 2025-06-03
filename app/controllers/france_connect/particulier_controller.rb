# frozen_string_literal: true

class FranceConnect::ParticulierController < ApplicationController
  before_action :redirect_to_login_if_fc_aborted, only: [:callback]
  before_action :securely_retrieve_fci, only: [:merge_using_fc_email, :merge_using_password, :send_email_merge_request]
  before_action :securely_retrieve_fci_from_email_merge_token, only: [:merge_using_email_link]
  before_action :set_user_by_confirmation_token, only: [:confirm_email]

  def login
    if FranceConnectService.enabled?
      redirect_to FranceConnectService.authorization_uri, allow_other_host: true
    else
      redirect_to new_user_session_path
    end
  end

  def callback
    @fci = FranceConnectService.find_or_retrieve_france_connect_information(params[:code])

    if @fci.user.nil?
      preexisting_unlinked_user = User.find_by(email: sanitize(@fci.email_france_connect))

      if preexisting_unlinked_user.nil?
        @fci.create_merge_token!
        render :choose_email
      elsif preexisting_unlinked_user.can_france_connect?
        @fci.create_merge_token!
        render :merge
      else
        destroy_fci_and_redirect_to_login(@fci)
      end
    else
      if @fci.user.can_france_connect?
        @fci.update(updated_at: Time.zone.now)
        connect_france_connect_particulier(@fci.user)
      else
        destroy_fci_and_redirect_to_login(@fci)
      end
    end

  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_to(new_user_session_path, alert: t('errors.messages.france_connect.connexion'))
  end

  def send_email_merge_request
    @fci.update(requested_email: sanitized_email_params)

    @fci.create_email_merge_token!
    UserMailer.france_connect_merge_confirmation(
      sanitized_email_params,
      @fci.email_merge_token,
      @fci.email_merge_token_created_at
    )
      .deliver_later

    redirect_to root_path, notice: t('france_connect.particulier.flash.confirmation_mail_sent')
  end

  def merge_using_fc_email
    @fci.safely_associate_user!(@fci.email_france_connect)

    sign_in(@fci.user)

    @fci.send_custom_confirmation_instructions

    render :confirmation_sent, locals: { email: @fci.email_france_connect, destination_path: destination_path(@fci.user) }
  end

  def merge_using_password
    user = User.find_by(email: sanitize(@fci.email_france_connect))

    if user.present? && !user.can_france_connect?
      return destroy_fci_and_redirect_to_login(@fci)
    end

    if user.present? && user.valid_for_authentication? { user.valid_password?(params[:password]) }
      @fci.safely_update_user(user:)

      flash.notice = t('france_connect.particulier.flash.connection_done', application_name: Current.application_name)
      connect_france_connect_particulier(user)
    else
      flash.alert = t('france_connect.particulier.flash.invalid_password')
    end
  end

  def merge_using_email_link
    user = User.find_by(email: @fci.requested_email)

    if user.present? && !user.can_france_connect?
      return destroy_fci_and_redirect_to_login(@fci)
    end

    if user.nil?
      @fci.safely_associate_user!(@fci.requested_email)
    else
      @fci.safely_update_user(user:)
    end

    @fci.user.update(email_verified_at: Time.zone.now)

    flash.notice = t('france_connect.particulier.flash.connection_done', application_name: Current.application_name)
    connect_france_connect_particulier(@fci.user)
  end

  # TODO mutualiser avec le controller Users::ActivateController
  # pour toute la partie de confirmation de compte
  def confirm_email
    if @user.confirmation_sent_at && 2.days.ago < @user.confirmation_sent_at
      @user.update(email_verified_at: Time.zone.now, confirmation_token: nil)
      @user.after_confirmation
      redirect_to destination_path(@user), notice: I18n.t('france_connect.particulier.flash.email_confirmed')
      return
    end

    fci = FranceConnectInformation.find_by(user: @user)

    if fci
      fci.send_custom_confirmation_instructions
      redirect_to root_path, notice: I18n.t('france_connect.particulier.flash.confirmation_mail_resent')
    else
      redirect_to root_path, alert: I18n.t('france_connect.particulier.flash.confirmation_mail_resent_error')
    end
  end

  private

  def set_user_by_confirmation_token
    @user = User.find_by(confirmation_token: params[:token])

    if @user.nil?
      return redirect_to root_path, alert: I18n.t('france_connect.particulier.flash.user_not_found')
    end

    if user_signed_in? && current_user != @user
      sign_out :user
      redirect_to new_user_session_path, alert: I18n.t('france_connect.particulier.flash.redirect_new_user_session')
    end
  end

  def destination_path(user) = stored_location_for(user) || root_path(user)

  def securely_retrieve_fci_from_email_merge_token
    @fci = FranceConnectInformation.find_by(email_merge_token: params[:email_merge_token])

    if @fci.nil? || !@fci.valid_for_email_merge?
      flash.alert = I18n.t('france_connect.particulier.flash.merger_token_expired', application_name: Current.application_name)

      redirect_to root_path
    else
      @fci.delete_email_merge_token!
    end
  end

  def securely_retrieve_fci
    @fci = FranceConnectInformation.find_by(merge_token: params[:merge_token])

    if @fci.nil? || !@fci.valid_for_merge?
      flash.alert = I18n.t('france_connect.particulier.flash.merger_token_expired', application_name: Current.application_name)

      redirect_to root_path
    end
  end

  def redirect_to_login_if_fc_aborted
    if params[:code].blank?
      redirect_to new_user_session_path
    end
  end

  def destroy_fci_and_redirect_to_login(fci)
    fci.destroy
    redirect_to new_user_session_path, alert: t('errors.messages.france_connect.forbidden_html', reset_link: new_user_password_path)
  end

  def connect_france_connect_particulier(user)
    sign_out :user if user_signed_in?
    sign_in user

    user.update_attribute('loged_in_with_france_connect', User.loged_in_with_france_connects.fetch(:particulier))

    redirect_to destination_path(current_user)
  end

  def sanitized_email_params
    sanitize(params[:email])
  end

  def sanitize(string)
    string&.gsub(/[[:space:]]/, ' ')&.strip&.downcase
  end
end
