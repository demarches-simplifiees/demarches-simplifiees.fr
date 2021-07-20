# This file is copied to spec/ when you run 'rails generate rspec:install'
# The generated `.rspec` file contains `--require rails_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'axe/rspec'
require 'devise'
require 'shoulda-matchers'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
Dir[Rails.root.join('spec/factories/**/*.rb')].each { |f| require f }

ActiveSupport::Deprecation.silenced = true

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

ActiveJob::Base.queue_adapter = :test

TPS::Application.load_tasks
Rake.application.options.trace = false

RSpec.configure do |config|
  # Since rspec 3.8.0, bisect uses fork to improve bisection speed.
  # This however fails as soon as we're running feature tests (which uses many processes).
  # Default to the :shell bisect runner, so that bisecting over feature tests works.
  config.bisect_runner = :shell

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.infer_base_class_for_anonymous_controllers = false

  config.before(:all) do
    Rake.verbose false

    Typhoeus::Expectation.clear

    ActionMailer::Base.deliveries.clear

    ActiveStorage::Current.host = 'http://test.host'

    Geocoder.configure(lookup: :test)
  end

  config.before(:each) do
    Flipper.enable(:instructeur_bypass_email_login_token)
  end

  # By default, forgery protection is disabled in the test environment.
  # (See `config.action_controller.allow_forgery_protection` in `config/test.rb`)
  #
  # Examples tagged with the :allow_forgery_protection have the forgery protection enabled anyway.
  config.around(:each, :allow_forgery_protection) do |example|
    previous_allow_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    begin
      example.call
    ensure
      ActionController::Base.allow_forgery_protection = previous_allow_forgery_protection
    end
  end

  # By default, the default HTML templates for exceptions are not rendered in the test environment.
  # (See `config.action_dispatch.show_exceptions` in `config/test.rb`)
  #
  # Examples tagged with the :show_exception_pages render the exception HTML page anyway.
  config.around(:each, :show_exception_pages) do |example|
    app = Rails.application
    previous_show_exceptions = app.env_config['action_dispatch.show_exceptions'] || app.config.action_dispatch.show_exceptions

    begin
      app.env_config['action_dispatch.show_exceptions'] = true
      example.call
    ensure
      app.env_config['action_dispatch.show_exceptions'] = previous_show_exceptions
    end
  end

  config.include Shoulda::Matchers::ActiveRecord, type: :model
  config.include Shoulda::Matchers::ActiveModel, type: :model
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
end
