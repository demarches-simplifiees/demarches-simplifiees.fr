FactoryBot.define do
  factory :piece_justificative do
    trait :rib do
      content { Rack::Test::UploadedFile.new("./spec/support/files/RIB.pdf", 'application/pdf') }
    end

    trait :contrat do
      content { Rack::Test::UploadedFile.new("./spec/support/files/Contrat.pdf", 'application/pdf') }
    end
  end
end
