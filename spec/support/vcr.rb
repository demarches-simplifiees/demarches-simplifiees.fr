# frozen_string_literal: true

VCR.configure do |c|
  c.ignore_localhost = true
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.configure_rspec_metadata!
  c.ignore_hosts 'test.host', 'chromedriver.storage.googleapis.com'

  c.filter_sensitive_data('redacted') do |interaction|
    auth = interaction.request.headers['Authorization']&.first
    next if auth.nil?

    if (match = auth.match(/^Bearer\s+([^,\s]+)/))
      match.captures.first
    end
  end
end
