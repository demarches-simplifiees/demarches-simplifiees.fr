FactoryGirl.define do
  factory :dossier do
    formulaire_id 12

    trait :with_entreprise do
      after(:build) do |dossier, _evaluator|
        etablissement = create(:etablissement)
        entreprise = create(:entreprise, etablissement: etablissement)
        dossier.entreprise = entreprise
        dossier.etablissement = etablissement
      end
    end

    trait :with_pieces_jointes do
      after(:build) do |dossier, _evaluator|
        dossier.build_default_pieces_jointes
      end
    end
  end
end
