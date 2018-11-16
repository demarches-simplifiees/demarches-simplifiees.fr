source 'https://rubygems.org'

gem 'dotenv-rails', require: 'dotenv/rails-now' # dotenv should always be loaded before rails
gem 'rails'

gem 'sassc-rails' # Use SCSS for stylesheets

gem 'jquery-rails' # Use jquery as the JavaScript library
gem 'turbolinks' # Turbolinks makes following links in your web application faster

gem 'deep_cloneable' # Enable deep clone of active record models

gem 'warden'

gem 'puma' # Use Puma as the app server

gem 'active_model_serializers'

gem 'haml-rails'

gem 'bootstrap-sass', '~> 3.3.5'

gem 'active_link_to' # Automatically set a class on active links

gem 'kaminari' # Pagination

gem 'devise' # Gestion des comptes utilisateurs
gem 'devise-async'
gem 'openid_connect'
gem 'omniauth-github'

gem 'rails-i18n' # Locales par défaut

gem 'rest-client'
gem 'typhoeus'

gem 'clamav-client', require: 'clamav/client'

gem 'carrierwave'
gem 'carrierwave-i18n'
gem 'copy_carrierwave_file'
gem 'fog-openstack'
gem 'activestorage-openstack', git: 'https://github.com/fredZen/activestorage-openstack.git', branch: 'frederic/fix_upload_signature'

gem 'pg'

gem 'bcrypt'

gem 'rgeo-geojson'

gem 'chartkick'

gem 'lograge'
gem 'logstash-event'

gem 'font-awesome-rails'

gem 'hashie'

gem 'mailjet'

gem 'premailer-rails'

gem 'smart_listing'

gem 'groupdate'

gem 'bootstrap-wysihtml5-rails', '~> 0.3.3.8'

gem 'spreadsheet_architect'
gem 'axlsx', '~> 3.0.0.pre' # https://github.com/randym/axlsx/issues/501#issuecomment-373640365

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

gem 'delayed_job_active_record'
gem 'daemons'
gem 'delayed_cron_job' # Cron jobs
gem 'delayed_job_web'
gem 'select2-rails'

gem 'prawn' # PDF Generation
gem 'prawn_rails'

gem 'chunky_png'
gem 'sentry-raven'

gem 'administrate'

gem 'rack-mini-profiler'

gem 'rake-progressbar', require: false

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

  gem 'capybara' # Integration testing
  gem 'capybara-selenium'
  gem 'capybara-screenshot' # Save a dump of the page when an integration test fails
  gem 'capybara-email' # Access emails during integration tests
end

group :development do
  gem 'brakeman', require: false
  gem 'web-console' # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'rack-handlers'
  gem 'xray-rails'
  gem 'rubocop', require: false
  gem 'rubocop-rspec-focused', require: false
  gem 'haml-lint'
  gem 'scss_lint', require: false
  gem 'letter_opener_web'
end

group :development, :test do
  gem 'byebug' # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry-byebug'

  gem 'spring' # Spring speeds up development by keeping your application running in the background
  gem 'spring-commands-rspec'
  gem 'rspec-rails'

  gem 'mina', git: 'https://github.com/mina-deploy/mina.git', require: false # Deploy

  gem 'rspec_junit_formatter'
end
