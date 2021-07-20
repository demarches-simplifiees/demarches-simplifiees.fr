require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Railtie.load

module TPS
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    Rails.autoloaders.main.ignore(Rails.root.join('lib/cops'))
    Rails.autoloaders.main.ignore(Rails.root.join('lib/linters'))
    Rails.autoloaders.main.ignore(Rails.root.join('lib/tasks/task_helper.rb'))
    config.paths.add Rails.root.join('spec/mailers/previews').to_s, eager_load: true

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Paris'

    # The default locale is :fr and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :fr
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.available_locales = [:fr, :en]
    config.i18n.fallbacks = [:fr]

    config.assets.paths << Rails.root.join('app', 'assets', 'javascript')
    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
    config.assets.precompile += ['.woff']

    default_allowed_tags = ActionView::Base.sanitized_allowed_tags
    config.action_view.sanitized_allowed_tags = default_allowed_tags + ['u']

    # ActionDispatch's IP spoofing detection is quite limited, and often rejects
    # legitimate requests from misconfigured proxies (such as mobile telcos).
    #
    # As we have our own proxy stack before reaching the Rails app, we can
    # disable the check performed by Rails.
    config.action_dispatch.ip_spoofing_check = false

    # Set the queue name for the mail delivery jobs to 'mailers'
    config.action_mailer.deliver_later_queue_name = :mailers

    # Set the queue name for the analysis jobs to 'active_storage_analysis'
    config.active_storage.queues.analysis = :active_storage_analysis

    config.to_prepare do
      # Make main application helpers available in administrate
      Administrate::ApplicationController.helper(TPS::Application.helpers)
    end

    config.middleware.use Rack::Attack
    config.middleware.use Flipper::Middleware::Memoizer,
      preload: [:instructeur_bypass_email_login_token]

    config.ds_env = ENV.fetch('DS_ENV', Rails.env)

    config.ds_weekly_overview = Rails.env.production? && config.ds_env != 'staging'

    config.ds_autosave = {
      debounce_delay: 3000,
      status_visible_duration: 6000
    }

    config.skylight.probes += [:graphql]
  end
end
