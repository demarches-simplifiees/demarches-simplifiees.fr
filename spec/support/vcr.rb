VCR.configure do |c|
  c.ignore_localhost = true
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.filter_sensitive_data('<FC_IDENTIFIER>') { Rails.application.secrets.france_connect_particulier[:identifier] }
  c.filter_sensitive_data('<FC_SECRET>') { Rails.application.secrets.france_connect_particulier[:secret] }
  c.configure_rspec_metadata!
  c.ignore_hosts 'test.host', 'chromedriver.storage.googleapis.com', 'www.example.com'
end
