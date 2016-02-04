source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.0'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', '~> 0.12.2', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.1.0'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 2.5.3'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.3.1'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
gem 'unicorn', '~> 4.9.0'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# serializer
gem 'active_model_serializers', '~> 0.8.3'

#haml
gem 'haml-rails', '~> 0.9.0'

#bootstrap saas
gem 'bootstrap-sass', '~> 3.3.5'

# Pagination
gem 'will_paginate-bootstrap', '~> 1.0.1'

# Decorators
gem 'draper', '~> 2.1.0'

#Gestion des comptes utilisateurs
gem 'devise', '~> 3.4.1'
gem 'openid_connect', '~> 0.9.2'
gem 'rest-client', '~> 1.8.0'

gem 'carrierwave', '~> 0.10.0'

gem 'pg', '~> 0.18.2'

gem 'rgeo-geojson', '~> 0.3.1'
gem 'leaflet-rails', '~> 0.7.4'
gem 'leaflet-markercluster-rails', '~> 0.7.0'
gem 'leaflet-draw-rails', '~> 0.1.0'

gem 'bootstrap-datepicker-rails', '~> 1.4.0'

gem 'chartkick', '~> 1.3.2'

gem 'logstasher', '~> 0.6.5'

gem "font-awesome-rails", '~> 4.4.0'

gem 'hashie', '~> 3.4.1'

gem 'mailjet', '~> 1.1.0'

gem "smart_listing", '~> 1.1.2'

gem 'swagger-docs'

group :test do
  gem 'capybara', '~> 2.1'
  gem 'factory_girl', '~> 4.5.0'
  gem 'database_cleaner', '~> 1.4.1'
  gem 'selenium-webdriver', '~> 2.44.0'
  gem 'webmock', '~> 1.21.0'
  gem 'shoulda-matchers', '~> 2.8.0', require: false
  gem 'simplecov', '~> 0.9.1', require: false
  gem 'poltergeist', '~> 1.6.0'
  gem 'timecop', '~> 0.7.3'
  gem 'guard', '~> 2.13.0'
  gem 'guard-rspec', '~> 4.3.1', require: false
  gem 'guard-livereload', '~> 2.5.1', require: false
end

group :development, :test do
  gem 'terminal-notifier', '~> 1.6.3'
  gem 'terminal-notifier-guard', '~> 1.6.4'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 5.0.0'
  gem 'pry-byebug', '~> 3.2.0'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.2.1'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 1.3.6'
  gem 'spring-commands-rspec', '~> 1.0.4'
  gem 'rspec-rails', '~> 3.2.0'

  gem 'railroady', '~> 1.3.0'

  gem 'rubocop', '~> 0.30.1', require: false
  gem 'rubocop-checkstyle_formatter', '~> 0.2.0', require: false
  gem 'rubocop-rspec', '~> 1.3.0', require: false

  gem "nyan-cat-formatter", '0.11'

  gem 'parallel_tests', '~> 1.9'

  # Deploy
  gem 'mina', git: 'https://github.com/mina-deploy/mina.git', :tag => 'v0.3.8'
end

group :production, :staging do
  gem 'sentry-raven', '~> 0.13.1'
end

