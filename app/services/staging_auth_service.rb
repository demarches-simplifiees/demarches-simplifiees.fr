class StagingAuthService
  CONFIG_PATH = Rails.root.join("config/basic_auth.yml")

  def self.authenticate(username, password)
    if enabled?
      username == config[:username] && password == config[:password]
    else
      true
    end
  end

  def self.enabled?
    !!config[:enabled]
  end

  def self.config
    if File.exists?(CONFIG_PATH)
      YAML.safe_load(File.read(CONFIG_PATH)).symbolize_keys
    else
      {}
    end
  end
end
