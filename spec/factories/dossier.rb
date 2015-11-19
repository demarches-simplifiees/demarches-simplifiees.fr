FactoryGirl.define do
  factory :dossier do
    nom_projet "Demande de subvention dans le cadre d'accompagnement d'enfant à l'étranger"
    state 'draft'

    trait :with_entreprise do
      after(:build) do |dossier, _evaluator|
        etablissement = create(:etablissement)
        entreprise = create(:entreprise, etablissement: etablissement)
        dossier.entreprise = entreprise
        dossier.etablissement = etablissement
      end
    end

    trait :with_procedure do
      after(:build) do |dossier, _evaluator|
        procedure = create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ)
        dossier.procedure = procedure
      end
    end

    trait :with_user do
      after(:build) do |dossier, _evaluator|
        dossier.user = create(:user)
      end
    end
  end
end
