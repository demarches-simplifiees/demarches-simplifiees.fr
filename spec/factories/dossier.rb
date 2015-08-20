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
  end
end