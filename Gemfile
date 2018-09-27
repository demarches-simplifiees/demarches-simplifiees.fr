source 'https://rubygems.org'

# dotenv should always be loaded before rails
gem 'dotenv-rails', require: 'dotenv/rails-now'
gem 'rails'

# Use SCSS for stylesheets
gem 'sass-rails'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Enable deep clone of active record models
gem 'deep_cloneable'

gem 'warden', git: 'https://github.com/hassox/warden.git', branch: 'master'

# Use Unicorn as the app server
gem 'unicorn'

# serializer
gem 'active_model_serializers'

# haml
gem 'haml-rails'

# bootstrap saas
gem 'bootstrap-sass', '~> 3.3.5'

# Automatically set a class on active links
gem 'active_link_to'

# Pagination
gem 'kaminari'

# Decorators
gem 'draper'

# Gestion des comptes utilisateurs
gem 'devise'
gem 'devise-async'
gem 'openid_connect'
gem 'omniauth-github'

# Locales par défaut
gem 'rails-i18n'

gem 'rest-client'
gem 'typhoeus'

gem 'clamav-client', require: 'clamav/client'

gem 'carrierwave'
gem 'carrierwave-i18n'
gem 'copy_carrierwave_file'
gem 'fog'
gem 'fog-openstack'

gem 'pg'

gem 'rbnacl-libsodium'
gem 'bcrypt'

gem 'rgeo-geojson'
gem 'leaflet-rails'
gem 'leaflet-markercluster-rails', '~> 0.7.0'
gem 'leaflet-draw-rails'

gem 'chartkick'

gem 'lograge'
gem 'logstash-event'

gem 'font-awesome-rails'

gem 'hashie'

gem 'mailjet'

gem "premailer-rails"

gem 'smart_listing'

gem 'groupdate'

gem 'bootstrap-wysihtml5-rails', '~> 0.3.3.8'

gem 'spreadsheet_architect'
gem 'axlsx', '~> 3.0.0.pre' # https://github.com/randym/axlsx/issues/501#issuecomment-373640365

gem 'apipie-rails'
# For Markdown support in apipie
gem 'maruku'

gem 'openstack'

gem 'browser'

gem 'simple_form'

gem 'skylight'

gem 'scenic'

gem 'sanitize-url'

gem 'flipflop'

gem 'aasm'

gem 'webpacker', '>= 4.0.x'

gem 'after_party'

gem 'zxcvbn-ruby', require: 'zxcvbn'

# Cron jobs
gem 'delayed_job_active_record'
gem "daemons"
gem 'delayed_cron_job'
gem "delayed_job_web"
gem 'select2-rails'

# PDF Generation
gem 'prawn'
gem 'prawn_rails'

gem 'chunky_png'
gem 'sentry-raven'

gem "administrate"

gem 'rack-mini-profiler'

group :test do
  gem 'launchy'
  gem 'factory_bot'
  gem 'database_cleaner'
  gem 'webmock'
  gem 'shoulda-matchers', require: false
  gem 'timecop'
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-livereload', require: false
  gem 'vcr'
  gem 'rails-controller-testing'

  # Integration testing
  gem 'capybara'
  gem 'capybara-selenium'
  # Save a dump of the page when an integration test fails
  gem 'capybara-screenshot'
end

group :development do
  gem 'brakeman', require: false
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'
  gem 'rack-handlers'
  gem 'xray-rails'
  gem 'rubocop', require: false
  gem 'rubocop-rspec-focused', require: false
  gem 'haml-lint'
  gem 'scss_lint', require: false
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'pry-byebug'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'rspec-rails'

  # Deploy
  gem 'mina', ref: '343a7', git: 'https://github.com/mina-deploy/mina.git'

  gem 'rspec_junit_formatter'
end
