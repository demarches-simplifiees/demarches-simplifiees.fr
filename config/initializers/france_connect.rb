FRANCE_CONNECT = if !Rails.env.test?
  file_path = "#{Rails.root}/config/france_connect.yml"
  Hashie::Mash.load(file_path)
else
  Hashie::Mash.new({
    particulier_identifier: 'plop',
    particulier_secret: 'plip',
    particulier_redirect_uri: 'https://bidon.com/endpoint',
    particulier_authorization_endpoint: 'https://bidon.com/endpoint',
    particulier_token_endpoint: 'https://bidon.com/endpoint',
    particulier_userinfo_endpoint: 'https://bidon.com/endpoint',
    particulier_logout_endpoint: 'https://bidon.com/endpoint',
  })
end
