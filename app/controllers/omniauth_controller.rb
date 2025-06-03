# frozen_string_literal: true

class OmniauthController < ApplicationController
  before_action :redirect_to_login_if_connection_aborted, only: [:callback]
  before_action :securely_retrieve_fci, only: [:merge, :merge_with_existing_account, :merge_with_new_account, :mail_merge_with_existing_account, :resend_and_renew_merge_confirmation]

  def login
    provider = provider_param
    # already checked in routes.rb but brakeman complains
    if OmniAuthService.enabled?(provider)
      redirect_to OmniAuthService.authorization_uri(provider), allow_other_host: true
    else
      redirect_to new_user_session_path
    end
  end

  def callback
    provider = provider_param
    fci = OmniAuthService.find_or_retrieve_user_informations(provider, params[:code])

    if fci.user.nil?
      preexisting_unlinked_user = User.find_by(email: fci.email_france_connect.downcase)

      if preexisting_unlinked_user.nil?
        fci.safely_associate_user!(fci.email_france_connect)
        connect_user(provider, fci.user)
      elsif !preexisting_unlinked_user.can_openid_connect?(provider)
        fci.destroy
        redirect_to new_user_session_path, alert: t('errors.messages.omniauth.forbidden_html', reset_link: new_user_password_path, provider: t("omniauth.provider.#{provider}"))
      else
        redirect_to omniauth_merge_path(provider, fci.create_merge_token!)
      end
    else
      user = fci.user

      if user.can_openid_connect?(provider)
        fci.update(updated_at: Time.zone.now)
        connect_user(provider, user)
      else # same behaviour as redirect nicely with message when instructeur/administrateur
        fci.destroy
        redirect_to new_user_session_path, alert: t('errors.messages.omniauth.forbidden_html', reset_link: new_user_password_path, provider: t("omniauth.provider.#{provider}"))
      end
    end

  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_error_connection(provider)
  end

  def merge
    @provider = provider_param
  end

  def merge_with_existing_account
    user = User.find_by(email: sanitized_email_params)
    provider = provider_param

    if user.present? && user.valid_for_authentication? { user.valid_password?(password_params) }
      if !user.can_openid_connect?(provider)
        flash.alert = t('errors.messages.omniauth.forbidden_html', reset_link: new_user_password_path, provider:)

        redirect_to root_path
      else
        @fci.safely_update_user(user: user)

        flash.notice = t('omniauth.flash.connection_done', application_name: Current.application_name, provider: t("omniauth.provider.#{provider}"))
        connect_user(provider, user)
      end
    else
      flash.alert = t('omniauth.flash.invalid_password')
    end
  end

  def mail_merge_with_existing_account
    user = User.find_by(email: @fci.email_france_connect.downcase)
    provider = provider_param
    if user.can_openid_connect?(provider)
      @fci.safely_update_user(user: user)

      flash.notice = t('omniauth.flash.connection_done', application_name: Current.application_name, provider: t("omniauth.provider.#{provider}"))
      connect_user(provider, user)
    else # same behaviour as redirect nicely with message when instructeur/administrateur
      @fci.destroy
      redirect_to new_user_session_path, alert: t('errors.messages.omniauth.forbidden_html', reset_link: new_user_password_path, provider: t("omniauth.provider.#{provider}"))
    end
  end

  def merge_with_new_account
    user = User.find_by(email: sanitized_email_params)
    provider = provider_param

    if user.nil?
      @fci.safely_associate_user!(sanitized_email_params)

      flash.notice = t('omniauth.flash.connection_done', application_name: Current.application_name, provider: t("omniauth.provider.#{provider}"))
      connect_user(provider, @fci.user)
    else
      @email = sanitized_email_params
      @merge_token = merge_token_params
      @provider = provider
    end
  end

  def resend_and_renew_merge_confirmation
    merge_token = @fci.create_merge_token!
    provider = provider_param
    redirect_to omniauth_merge_path(provider:, merge_token:),
                notice: t('omniauth.flash.confirmation_mail_sent')
  end

  private

  def securely_retrieve_fci
    @fci = FranceConnectInformation.find_by(merge_token: merge_token_params)
    provider = provider_param

    if @fci.nil? || !@fci.valid_for_merge?
      flash.alert = t('omniauth.flash.merger_token_expired', application_name: Current.application_name, provider: t("omniauth.provider.#{provider}"))

      redirect_to root_path
    end
  end

  def redirect_to_login_if_connection_aborted
    if params[:code].blank?
      redirect_to new_user_session_path
    end
  end

  def connect_user(provider, user)
    if user_signed_in?
      sign_out :user
    end

    sign_in user

    user.update_attribute('loged_in_with_france_connect', User.loged_in_with_france_connects.fetch(provider))

    redirect_to stored_location_for(current_user) || root_path(current_user)
  end

  def provider_param
    params[:provider]
  end

  def redirect_error_connection(provider)
    flash.alert = t("errors.messages.omniauth.connexion", provider: t("omniauth.provider.#{provider}"))
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
