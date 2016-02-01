namespace :dev do
  desc 'Initialise dev environment'
  task :init  do
    puts 'start initialisation'
    Rake::Task['dev:generate_secret_token_file'].invoke
    Rake::Task['dev:generate_clients_basic_auth'].invoke
    puts 'end initialisation'
  end

  task :generate_clients_basic_auth  do
    puts 'creating clients_basic_auth.yml file'
    file = File.new('config/clients_basic_auth.yml',  'w+')
    credentials = <<EOF
username: toto
password: password
EOF
    file.write(credentials)
    file.close
  end

  task :generate_secret_token_file  do
    puts 'creating secret_token.rb file'
    res = `rake secret`.gsub("\n", '')
    file = File.new('config/initializers/secret_token.rb',  'w+')
    comment = <<EOF
# Be sure to restart your server when you modify this file.
# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
EOF
    file.write(comment)
    file.write("TPS::Application.config.secret_key_base = '#{res}'")
    file.close
  end
end
