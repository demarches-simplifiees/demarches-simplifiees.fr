source 'https://rubygems.org'

gem 'aasm'
gem 'active_link_to' # Automatically set a class on active links
gem 'active_model_serializers'
gem 'activestorage-openstack', git: 'https://github.com/fredZen/activestorage-openstack.git', branch: 'frederic/fix_upload_signature'
gem 'administrate'
gem 'after_party'
gem 'axlsx', '~> 3.0.0.pre' # https://github.com/randym/axlsx/issues/501#issuecomment-373640365
gem 'bcrypt'
gem 'bootstrap-sass', '~> 3.3.5'
gem 'bootstrap-wysihtml5-rails', '~> 0.3.3.8'
gem 'browser'
gem 'carrierwave'
gem 'carrierwave-i18n'
gem 'chartkick'
gem 'chunky_png'
gem 'clamav-client', require: 'clamav/client'
gem 'copy_carrierwave_file'
gem 'daemons'
gem 'deep_cloneable' # Enable deep clone of active record models
gem 'delayed_cron_job' # Cron jobs
gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'devise' # Gestion des comptes utilisateurs
gem 'devise-async'
gem 'dotenv-rails', require: 'dotenv/rails-now' # dotenv should always be loaded before rails
gem 'flipflop'
gem 'fog-openstack'
gem 'font-awesome-rails'
gem 'groupdate'
gem 'haml-rails'
gem 'hashie'
gem 'jquery-rails' # Use jquery as the JavaScript library
gem 'kaminari' # Pagination
gem 'lograge'
gem 'logstash-event'
gem 'mailjet'
gem 'omniauth-github'
gem 'openid_connect'
gem 'openstack'
gem 'pg'
gem 'prawn' # PDF Generation
gem 'prawn_rails'
gem 'premailer-rails'
gem 'puma' # Use Puma as the app server
gem 'rack-mini-profiler'
gem 'rails'
gem 'rails-i18n' # Locales par défaut
gem 'rake-progressbar', require: false
gem 'rest-client'
gem 'rgeo-geojson'
gem 'sanitize-url'
gem 'sassc-rails' # Use SCSS for stylesheets
gem 'scenic'
gem 'select2-rails'
gem 'sentry-raven'
gem 'simple_form'
gem 'skylight'
gem 'smart_listing'
gem 'spreadsheet_architect'
gem 'turbolinks' # Turbolinks makes following links in your web application faster
gem 'typhoeus'
gem 'warden'
gem 'webpacker', '>= 4.0.x'
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
  gem 'webmock'
end

group :development do
  gem 'brakeman', require: false
  gem 'haml-lint'
  gem 'letter_opener_web'
  gem 'rubocop', require: false
  gem 'rubocop-rspec-focused', require: false
  gem 'scss_lint', require: false
  gem 'web-console' # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'xray-rails'
end

group :development, :test do
  gem 'byebug' # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'mina', git: 'https://github.com/mina-deploy/mina.git', require: false # Deploy
  gem 'pry-byebug'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'spring' # Spring speeds up development by keeping your application running in the background
  gem 'spring-commands-rspec'
end
