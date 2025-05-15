# frozen_string_literal: true

class Rack::Attack
  # Note: limits use Rails.cache, which is global between our webservers.

  signin_limit = ENV.fetch('RACK_ATTACK_SIGNIN_LIMIT', 0).to_i
  if signin_limit > 0
    throttle('/users/sign_in/ip', limit: signin_limit, period: 15.seconds) do |req|
      if req.path == '/users/sign_in' && req.post? && rack_attack_enabled?
        req.remote_ip
      end
    end
  end

  throttle('stats/ip', limit: 5, period: 15.seconds) do |req|
    if req.path == '/stats' && rack_attack_enabled?
      req.remote_ip
    end
  end

  throttle('contact/ip', limit: 5, period: 15.seconds) do |req|
    if req.path == '/contact' && req.post? && rack_attack_enabled?
      req.remote_ip
    end
  end

  # API prefill
  throttle('/api/public/v1/dossiers/ip', limit: 15, period: 15.seconds) do |req|
    if req.path == '/api/public/v1/dossiers' && req.post? && rack_attack_enabled?
      req.remote_ip
    end
  end

  Rack::Attack.safelist('allow trusted ips') do |req|
    IPService.ip_trusted?(req.remote_ip)
  end

  def self.rack_attack_enabled?
    ENV['RACK_ATTACK_ENABLE'] == 'true'
  end
end
