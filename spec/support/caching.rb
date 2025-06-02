# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:example, :caching) do |example|
    caching_was = ActionController::Base.perform_caching
    cache_store_was = Rails.cache

    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    ActionController::Base.perform_caching = true
    ActionController::Base.cache_store = Rails.cache

    example.run
  ensure
    Rails.cache = cache_store_was
    ActionController::Base.perform_caching = caching_was
    ActionController::Base.cache_store = Rails.cache
  end
end
