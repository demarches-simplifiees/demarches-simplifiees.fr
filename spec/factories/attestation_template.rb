FactoryBot.define do
  factory :attestation_template do
    title { 'title' }
    body { 'body' }
    footer { 'footer' }
    activated { true }
  end

  trait :with_files do
    logo_active_storage { Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png') }
    signature_active_storage { Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png') }
  end

  trait :with_legacy_files do
    logo { Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png') }
    signature { Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png') }
  end
end
