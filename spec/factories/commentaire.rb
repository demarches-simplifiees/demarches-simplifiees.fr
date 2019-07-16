FactoryBot.define do
  factory :commentaire do
    body { 'plop' }

    before(:create) do |commentaire, _evaluator|
      if !commentaire.dossier
        commentaire.dossier = create :dossier, :en_construction
      end
    end

    trait :with_file do
      file { Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'application/pdf') }
    end
  end
end
