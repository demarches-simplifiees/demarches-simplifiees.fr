class StagingAuthService
  def self.authenticate(username, password)
    if enabled?
      username == Rails.application.secrets.basic_auth[:username] && password == Rails.application.secrets.basic_auth[:password]
    else
      true
    end
  end

  def self.enabled?
    ENV['BASIC_AUTH_ENABLED'] == 'enabled'
  end
end
