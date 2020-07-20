FactoryBot.define do
  factory :commentaire do
    association :dossier, :en_construction

    body { 'plop' }

    trait :with_file do
      piece_jointe { Rack::Test::UploadedFile.new('spec/fixtures/files/logo_test_procedure.png', 'image/png') }
    end
  end
end
