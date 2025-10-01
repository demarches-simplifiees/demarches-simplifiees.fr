# frozen_string_literal: true

ReActionView.configure do |config|
  # Intercept .html.erb templates and process them with `Herb::Engine` for enhanced features
  # config.intercept_erb = true

  # Enable debug mode in development (adds debug elements and attributes to HTML, may break design).
  config.debug_mode = Rails.env.development? && ENV["REACTIONVIEW_DEBUG"].present?
end
