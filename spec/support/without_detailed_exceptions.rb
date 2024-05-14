# frozen_string_literal: true

module WithoutDetailedExceptions
  RSpec.configure do |config|
    config.include self, type: :system
  end

  # Snippet from https://github.com/rspec/rspec-rails/issues/2024
  def without_detailed_exceptions
    env_config = Rails.application.env_config
    original_show_exceptions = env_config['action_dispatch.show_exceptions']
    original_show_detailed_exceptions = env_config['action_dispatch.show_detailed_exceptions']
    env_config['action_dispatch.show_exceptions'] = true
    env_config['action_dispatch.show_detailed_exceptions'] = false
    yield
  ensure
    env_config['action_dispatch.show_exceptions'] = original_show_exceptions
    env_config['action_dispatch.show_detailed_exceptions'] = original_show_detailed_exceptions
  end
end
