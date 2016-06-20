source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5.2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Enable deep clone of active record models
gem 'deep_cloneable', '~> 2.2.1'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# serializer
gem 'active_model_serializers'

#haml
gem 'haml-rails'

#bootstrap saas
gem 'bootstrap-sass', '~> 3.3.5'

# Pagination
gem 'will_paginate-bootstrap'

# Decorators
gem 'draper'

#Gestion des comptes utilisateurs
gem 'devise'
gem 'openid_connect'

gem 'rest-client'

gem 'clamav-client', require: 'clamav/client'

gem 'carrierwave'
gem 'fog'
gem 'fog-openstack'

gem 'pg'

gem 'rgeo-geojson'
gem 'leaflet-rails'
gem 'leaflet-markercluster-rails', '~> 0.7.0'
gem 'leaflet-draw-rails'

gem 'bootstrap-datepicker-rails'

gem 'chartkick'

gem 'logstasher'

gem "font-awesome-rails"

gem 'hashie'

gem 'mailjet'

gem "smart_listing"

gem 'css_splitter'
gem 'bootstrap-wysihtml5-rails', '~> 0.3.3.8'

gem 'as_csv'

gem 'apipie-rails', '=0.3.1'
gem "maruku" # for Markdown support in apipie

group :test do
  gem 'capybara'
  gem 'factory_girl'
  gem 'database_cleaner'
  gem 'selenium-webdriver'
  gem 'webmock'
  gem 'shoulda-matchers', require: false
  gem 'simplecov', require: false
  gem 'poltergeist'
  gem 'timecop'
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-livereload', '~> 2.4', require: false
  gem 'vcr'
end

group :development, :test do
  gem 'terminal-notifier'
  gem 'terminal-notifier-guard'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'pry-byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'rspec-rails', '~> 3.0'

  gem 'railroady'

  gem 'rubocop', require: false
  gem 'rubocop-checkstyle_formatter', require: false
  gem 'rubocop-rspec', require: false

  gem "nyan-cat-formatter"

  gem 'parallel_tests'

  gem 'brakeman', require: false
  # Deploy
  gem 'mina', git: 'https://github.com/mina-deploy/mina.git'
end

group :production, :staging do
  gem 'sentry-raven'
end

