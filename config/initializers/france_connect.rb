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
    },
    agent: {
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
  conf = YAML.safe_load(File.read(fc_config_file_path))

  # FIXME: with a yaml with a { particulier: {} } structure
  old_file = File.readlines(fc_config_file_path).any? { |line| line.include?('particulier_') }

  if old_file
    particulier_hash = conf
      .select { |(key, _)| key.start_with?('particulier_') }
      .reduce({}) { |acc, (key, value)| acc[key.gsub('particulier_', '')] = value; acc }
      .symbolize_keys

    agent_hash = conf
      .select { |(key, _)| key.start_with?('agent_') }
      .reduce({}) { |acc, (key, value)| acc[key.gsub('agent_', '')] = value; acc }
      .symbolize_keys

    { particulier: particulier_hash, agent: agent_hash }
  else
    conf.deep_symbolize_keys
  end
end
