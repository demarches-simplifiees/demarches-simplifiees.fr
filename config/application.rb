require File.expand_path('boot', __dir__)

require 'rails/all'
require_relative 'application_name'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Railtie.load

module TPS
  class Application < Rails::Application
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # The default autoloader since Rails 6.0 defaults is zeitwerk.
    # However, to split the work, we will move to zeitwerk only in a future PR.
    config.autoloader = :classic

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

    config.active_job.queue_adapter = :delayed_job

    # The default list used to be accessible through `ActionView::Base.sanitized_allowed_tags`,
    # but a regression in Rails 6.0 makes it unavailable.
    # It should be fixed in Rails 6.1.
    # See https://github.com/rails/rails/issues/39586
    # default_allowed_tags = ActionView::Base.sanitized_allowed_tags
    default_allowed_tags = ['strong', 'em', 'b', 'i', 'p', 'code', 'pre', 'tt', 'samp', 'kbd', 'var', 'sub', 'sup', 'dfn', 'cite', 'big', 'small', 'address', 'hr', 'br', 'div', 'span', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li', 'dl', 'dt', 'dd', 'abbr', 'acronym', 'a', 'img', 'blockquote', 'del', 'ins']
    config.action_view.sanitized_allowed_tags = default_allowed_tags + ['u']

    # Some mobile browsers have a behaviour where, although they will delete the session
    # cookie when the browser shutdowns, they will still serve a cached version
    # of the page on relaunch.
    # The CSRF token in the HTML is then mismatched with the CSRF token in the session cookie
    # (because the session cookie has been cleared). This causes form submissions to fail with
    # a "ActionController::InvalidAuthenticityToken" exception.
    # To prevent this, tell browsers to never cache the HTML of a page.
    # (This doesn’t affect assets files, which are still sent with the proper cache headers).
    #
    # See https://github.com/rails/rails/issues/21948
    config.action_dispatch.default_headers['Cache-Control'] = 'no-store, no-cache'

    config.to_prepare do
      # Make main application helpers available in administrate
      Administrate::ApplicationController.helper(TPS::Application.helpers)
    end

    config.middleware.use Rack::Attack
    config.middleware.use Flipper::Middleware::Memoizer, preload_all: true

    config.ds_weekly_overview = ENV['APP_NAME'] == 'tps'

    config.ds_autosave = {
      debounce_delay: 3000,
      status_visible_duration: 6000
    }

    config.skylight.probes += [:graphql]
  end
end
