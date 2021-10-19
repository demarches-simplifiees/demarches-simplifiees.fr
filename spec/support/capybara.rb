require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'capybara/email/rspec'
require "capybara/cuprite"

Capybara.javascript_driver = :cuprite
Capybara.ignore_hidden_elements = false

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1440, 900], headless: true, browser_options: { "disable-dev-shm-usage" => nil, "disable-software-rasterizer" => nil, "mute-audio" => nil })
end

# FIXME: remove this line when https://github.com/rspec/rspec-rails/issues/1897 has been fixed
Capybara.server = :puma, { Silent: true }

Capybara.default_max_wait_time = 2

# Save a snapshot of the HTML page when an integration test fails
Capybara::Screenshot.autosave_on_failure = true
# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run
# Tell Capybara::Screenshot how to take screenshots when using the headless_chrome driver
Capybara::Screenshot.register_driver :headless_chrome do |driver, path|
  driver.browser.save_screenshot(path)
end

RSpec.configure do |config|
  # Examples tagged with :capybara_ignore_server_errors will allow Capybara
  # to continue when an exception in raised by Rails.
  # This allows to test for error cases.
  config.around(:each, :capybara_ignore_server_errors) do |example|
    Capybara.raise_server_errors = false

    example.run
  ensure
    Capybara.raise_server_errors = true
  end
end
