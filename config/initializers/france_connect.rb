FRANCE_CONNECT = if Rails.env.test?
  {
    identifier: 'plop',
    secret: 'plip',
    redirect_uri: 'https://bidon.com/endpoint',
    authorization_endpoint: 'https://bidon.com/endpoint',
    token_endpoint: 'https://bidon.com/endpoint',
    userinfo_endpoint: 'https://bidon.com/endpoint',
    logout_endpoint: 'https://bidon.com/endpoint',
  }
else
  fc_config_file_path = "#{Rails.root}/config/france_connect.yml"
  YAML.safe_load(File.read(fc_config_file_path)).symbolize_keys
end
