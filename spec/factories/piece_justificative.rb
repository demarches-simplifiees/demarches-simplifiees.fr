FactoryBot.define do
  factory :piece_justificative do
    trait :rib do
      content { Rack::Test::UploadedFile.new("./spec/fixtures/files/RIB.pdf", 'application/pdf') }
    end

    trait :contrat do
      content { Rack::Test::UploadedFile.new("./spec/fixtures/files/Contrat.pdf", 'application/pdf') }
    end
  end
end
