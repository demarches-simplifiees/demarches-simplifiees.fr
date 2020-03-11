FactoryBot.define do
  factory :attestation_template do
    title { 'title' }
    body { 'body' }
    footer { 'footer' }
    activated { true }
  end

  trait :with_files do
    logo { Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png') }
    signature { Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png') }
  end

  trait :with_gif_files do
    logo { Rack::Test::UploadedFile.new('./spec/fixtures/files/french-flag.gif', 'image/gif') }
    signature { Rack::Test::UploadedFile.new('./spec/fixtures/files/beta-gouv.gif', 'image/gif') }
  end
end
