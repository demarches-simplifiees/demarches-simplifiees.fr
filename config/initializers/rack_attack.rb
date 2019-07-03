if ENV['RAILS_ENV'] != 'test'
  class Rack::Attack
    throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
      if req.path == '/users/sign_in' && req.post?
        req.ip
      end
    end

    throttle('stats/ip', limit: 5, period: 20.seconds) do |req|
      if req.path == '/stats'
        req.ip
      end
    end

    throttle('contact/ip', limit: 5, period: 20.seconds) do |req|
      if req.path == '/contact' && req.post?
        req.ip
      end
    end
  end
end
