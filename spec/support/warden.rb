# frozen_string_literal: true

include Warden::Test::Helpers

RSpec.configure do |config|
  config.before(:all) do
    Warden.test_mode!
  end
end
