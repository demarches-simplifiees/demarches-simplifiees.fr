# frozen_string_literal: true

module ApplicationController::LongLivedAuthenticityToken
  extend ActiveSupport::Concern

  COOKIE_NAME = :_csrf_token

  # Override ActionController::RequestForgeryProtection#real_csrf_token with a
  # version that reads from an external long-lived cookie (instead of reading from the session).
  #
  # See also:
  # - The Architecture Documentation Record for this choice: docs/adr-csrf-forgery.md
  # - The Rails issue: https://github.com/rails/rails/issues/21948
  def real_csrf_token(session) # :doc:
    # Read the CSRF token from the external long-lived cookie (or generate a new one)
    #
    # NB: For retro-compatibility with tokens created before this code was deployed,
    # also try to read the token from the session.

    csrf_token = cookies.signed[COOKIE_NAME] || session[:_csrf_token] || generate_csrf_token

    # Write the (potentially new) token to an external long-lived cookie.
    #
    # NB: for forward-compatibility if we ever remove this code and revert back to session cookies,
    # also write the token to the session.
    cookies.signed[COOKIE_NAME] = {
      value: csrf_token,
      expires: 1.year.from_now,
      httponly: true,
      secure: Rails.env.production?
    }
    session[:_csrf_token] = csrf_token

    decode_csrf_token(csrf_token)
  end
end

# Clean-up the long-lived cookie if the winning strategy requests so.
# See:
# - devise-4.2.0/lib/devise/hooks/csrf_cleaner.rb
# - http://blog.plataformatec.com.br/2013/08/csrf-token-fixation-attacks-in-devise/
Warden::Manager.after_authentication do |_record, warden, _options|
  clean_up_for_winning_strategy = !warden.winning_strategy.respond_to?(:clean_up_csrf?) ||
    warden.winning_strategy.clean_up_csrf?
  if Devise.clean_up_csrf_token_on_authentication && clean_up_for_winning_strategy
    warden.cookies.delete(ApplicationController::LongLivedAuthenticityToken::COOKIE_NAME)
  end
end
