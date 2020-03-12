FactoryBot.define do
  factory :bill_signature do
    trait :with_serialized do
      serialized { Rack::Test::UploadedFile.new("./spec/fixtures/files/bill_signature/serialized.json", 'application/json') }
    end
    trait :with_signature do
      signature { Rack::Test::UploadedFile.new("./spec/fixtures/files/bill_signature/signature.der", 'application/x-x509-ca-cert') }
    end
  end
end
