# frozen_string_literal: true

Typhoeus::Config.user_agent = APPLICATION_NAME

Rails.application.config.after_initialize do
  Typhoeus::Config.cache = Typhoeus::Cache::SuccessfulRequestsRailsCache.new
end
