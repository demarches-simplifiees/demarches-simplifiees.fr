class StagingAuthService
  def self.authenticate(username, password)
    if enabled?
      username == ENV['BASIC_AUTH_USERNAME'] && password == ENV['BASIC_AUTH_PASSWORD']
    else
      true
    end
  end

  def self.enabled?
    ENV['BASIC_AUTH_ENABLED'] == 'enabled'
  end
end
