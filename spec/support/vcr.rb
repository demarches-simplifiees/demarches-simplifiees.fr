VCR.configure do |c|
  c.ignore_localhost = true
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.configure_rspec_metadata!
  c.ignore_hosts 'test.host', 'chromedriver.storage.googleapis.com'
  c.filter_sensitive_data("<GRAVITEE>") { Rails.application.secrets.api_ispf_entreprise[:gravitee] }
end
