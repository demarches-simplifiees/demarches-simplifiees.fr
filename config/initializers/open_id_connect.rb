# frozen_string_literal: true

OpenIDConnect.http_config do |config|
  config.response :jwt

  if ENV['http_proxy'].present?
    config.proxy = ENV['http_proxy']
  end
end
