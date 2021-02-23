source 'https://rubygems.org'

gem 'aasm'
gem 'active_link_to' # Automatically set a class on active links
gem 'active_model_serializers'
gem 'activestorage-openstack'
gem 'active_storage_validations'
gem 'administrate'
gem 'after_party'
gem 'anchored'
gem 'bcrypt'
gem 'browser'
gem 'chartkick'
gem 'chunky_png'
gem 'clamav-client', require: 'clamav/client'
gem 'daemons'
gem 'deep_cloneable' # Enable deep clone of active record models
gem 'delayed_cron_job' # Cron jobs
gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'devise' # Gestion des comptes utilisateurs
gem 'devise-async'
gem 'devise-i18n'
gem 'devise-two-factor', github: 'jason-hobbs/devise-two-factor', branch: 'master' # Rails 6.1 compatibility: https://github.com/tinfoil/devise-two-factor/issues/183
gem 'discard'
gem 'dotenv-rails', require: 'dotenv/rails-now' # dotenv should always be loaded before rails
gem 'flipper'
gem 'flipper-active_record'
gem 'flipper-ui'
gem 'fugit'
gem 'geocoder'
gem 'geo_coord', require: "geo/coord"
gem 'gon'
gem 'graphql'
gem 'graphql-batch'
gem 'graphql_playground-rails'
gem 'graphql-rails_logger'
gem 'groupdate'
gem 'haml-rails'
gem 'hashie'
gem 'http_accept_language'
gem 'i18n-tasks'
gem 'iban-tools'
gem 'image_processing'
gem 'json_schemer'
gem 'jwt'
gem 'kaminari', '1.2.1' # Pagination
gem 'lograge'
gem 'logstash-event'
gem 'mailjet'
gem 'openid_connect'
gem 'pg'
gem 'phonelib'
gem 'prawn-rails' # PDF Generation
gem 'prawn-svg'
gem 'premailer-rails'
gem 'puma' # Use Puma as the app server
gem 'pundit'
gem 'rack-attack'
gem 'rails'
gem 'rails-i18n' # Locales par défaut
gem 'rake-progressbar', require: false
gem 'react-rails'
gem 'rgeo-geojson'
gem 'rqrcode'
gem 'ruby-saml-idp'
gem 'sanitize-url'
gem 'sassc-rails' # Use SCSS for stylesheets
gem 'sentry-delayed_job'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'sib-api-v3-sdk'
gem 'skylight'
gem 'smart_listing'
gem 'spreadsheet_architect'
gem 'typhoeus'
gem 'warden'
gem 'webpacker'
gem 'zipline'
gem 'zxcvbn-ruby', require: 'zxcvbn'

group :test do
  gem 'capybara' # Integration testing
  gem 'capybara-email' # Access emails during integration tests
  gem 'capybara-screenshot' # Save a dump of the page when an integration test fails
  gem 'capybara-selenium'
  gem 'database_cleaner'
  gem 'factory_bot'
  gem 'guard'
  gem 'guard-livereload', require: false
  gem 'guard-rspec', require: false
  gem 'launchy'
  gem 'rails-controller-testing'
  gem 'shoulda-matchers', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webdrivers', '~> 4.0'
  gem 'webmock'
end

group :development do
  gem 'annotate'
  gem 'brakeman', require: false
  gem 'haml-lint'
  gem 'letter_opener_web'
  gem 'rack-mini-profiler'
  gem 'rails-erd', require: false # generates `doc/database_models.pdf`
  gem 'rubocop', require: false
  gem 'rubocop-rails_config'
  gem 'rubocop-rspec-focused', require: false
  gem 'scss_lint', require: false
  gem 'web-console'
end

group :development, :test do
  gem 'axe-matchers' # accessibility rspec matchers
  gem 'graphql-schema_comparator'
  gem 'mina', git: 'https://github.com/mina-deploy/mina.git', require: false # Deploy
  gem 'pry-byebug' # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'rspec_junit_formatter', require: false
  gem 'rspec-rails'
  gem 'ruby-debug-ide', require: false
  gem 'simple_xlsx_reader'
  gem 'spring' # Spring speeds up development by keeping your application running in the background
  gem 'spring-commands-rspec'
end
