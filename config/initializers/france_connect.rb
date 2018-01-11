FRANCE_CONNECT = if !Rails.env.test?
  file_path = "#{Rails.root}/config/france_connect.yml"
  Hashie::Mash.load(file_path)
else
  Hashie::Mash.new({
    identifier: 'plop',
    secret: 'plip',
    redirect_uri: 'https://bidon.com/endpoint',
    authorization_endpoint: 'https://bidon.com/endpoint',
    token_endpoint: 'https://bidon.com/endpoint',
    userinfo_endpoint: 'https://bidon.com/endpoint',
    logout_endpoint: 'https://bidon.com/endpoint',
  })
end
