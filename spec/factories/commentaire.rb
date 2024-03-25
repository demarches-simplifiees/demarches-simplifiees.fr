FactoryBot.define do
  factory :commentaire do
    association :dossier, :en_construction
    email { generate(:user_email) }
    body { 'plop' }

    trait :with_file do
      after(:build) do |commentaire|
        commentaire.piece_jointe.attach(
          io: File.open('spec/fixtures/files/logo_test_procedure.png'),
          filename: 'logo_test_procedure.png',
          content_type: 'image/png'
        )
      end
    end
  end
end
