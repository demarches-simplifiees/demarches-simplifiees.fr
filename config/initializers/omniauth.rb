# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :rdv_service_public, ENV["RDV_SERVICE_PUBLIC_OAUTH_APP_ID"], ENV["RDV_SERVICE_PUBLIC_OAUTH_APP_SECRET"],
           scope: "write", base_url: ENV["RDV_SERVICE_PUBLIC_URL"]

  # on_failure do |env|
  #   Sentry.capture_exception(env["omniauth.error"])

  #   # redirect to the root path
  #   redirect_to root_path
  # end
end
