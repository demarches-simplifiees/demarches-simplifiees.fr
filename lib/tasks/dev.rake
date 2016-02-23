namespace :dev do
  desc 'Initialise dev environment'
  task :init  do
    puts 'start initialisation'
    Rake::Task['dev:generate_token_file'].invoke
    Rake::Task['dev:generate_franceconnect_file'].invoke

    puts 'end initialisation'
  end

  task :generate_token_file  do
    puts 'creating token.rb file'
    res = `rake secret`.gsub("\n", '')
    file = File.new('config/initializers/token.rb',  'w+')
    comment = <<EOF
EOF
    file.write(comment)
    file.write("TPS::Application.config.SIADETOKEN = '#{res}'")
    file.close
  end

  task :generate_franceconnect_file do
    file = File.new('config/france_connect.yml',  'w+')
    comment = <<EOF
particulier_identifier: plop
particulier_secret: plip

particulier_redirect_uri: 'http://localhost:3000/france_connect/particulier/callback'

particulier_authorization_endpoint: 'https://fcp.integ01.dev-franceconnect.fr/api/v1/authorize'
particulier_token_endpoint: 'https://fcp.integ01.dev-franceconnect.fr/api/v1/token'
particulier_userinfo_endpoint: 'https://fcp.integ01.dev-franceconnect.fr/api/v1/userinfo'
particulier_logout_endpoint: 'https://fcp.integ01.dev-franceconnect.fr/api/v1/logout'
EOF
    file.write(comment)
    file.close
  end
end
