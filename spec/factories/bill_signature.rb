FactoryBot.define do
  factory :bill_signature do
    serialized { Rack::Test::UploadedFile.new("./spec/fixtures/files/bill_signature/serialized.json", 'application/json') }
    signature { Rack::Test::UploadedFile.new("./spec/fixtures/files/bill_signature/signature.der", 'application/x-x509-ca-cert') }
  end
end
