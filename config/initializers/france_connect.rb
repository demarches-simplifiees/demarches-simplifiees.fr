FRANCE_CONNECT = if Rails.env.test?
  {
    particulier: {
      identifier: 'plop',
      secret: 'plip',
      redirect_uri: 'https://bidon.com/endpoint',
      authorization_endpoint: 'https://bidon.com/endpoint',
      token_endpoint: 'https://bidon.com/endpoint',
      userinfo_endpoint: 'https://bidon.com/endpoint',
      logout_endpoint: 'https://bidon.com/endpoint',
    }
  }
else
  fc_config_file_path = "#{Rails.root}/config/france_connect.yml"

  # FIXME: with a yaml with a { particulier: {} } structure
  config_hash = YAML.safe_load(File.read(fc_config_file_path))
    .reduce({}) { |acc, (key, value)| acc[key.gsub('particulier_', '')] = value; acc }
    .symbolize_keys

  { particulier: config_hash }
end
