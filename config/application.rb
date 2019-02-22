require File.expand_path('boot', __dir__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Railtie.load

module TPS
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Paris'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :fr
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.available_locales = [:fr]

    config.paths.add "#{config.root}/lib", eager_load: true
    config.paths.add "#{config.root}/app/controllers/concerns", eager_load: true

    config.assets.paths << Rails.root.join('app', 'assets', 'javascript')
    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
    config.assets.precompile += ['.woff']

    URL = 'http://' + ENV.fetch('APP_HOST', 'localhost:3000')

    config.active_job.queue_adapter = :delayed_job

    config.action_view.sanitized_allowed_tags = ActionView::Base.sanitized_allowed_tags + ['u']
  end
end
