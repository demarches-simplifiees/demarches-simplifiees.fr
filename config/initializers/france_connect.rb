FRANCE_CONNECT = if !Rails.env.test?
  file_path = "#{Rails.root}/config/france_connect.yml"
  config_hash = YAML.safe_load(File.read(file_path))
    .reduce({}) { |acc, (key, value)| acc[key.gsub('particulier_', '')] = value, acc }

  Hashie::Mash.new(particulier: config_hash)
else
  Hashie::Mash.new({
    particulier: {
      identifier: 'plop',
      secret: 'plip',
      redirect_uri: 'https://bidon.com/endpoint',
      authorization_endpoint: 'https://bidon.com/endpoint',
      token_endpoint: 'https://bidon.com/endpoint',
      userinfo_endpoint: 'https://bidon.com/endpoint',
      logout_endpoint: 'https://bidon.com/endpoint',
    }
  })
end
