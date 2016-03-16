FactoryGirl.define do
  factory :dossier do
    nom_projet "Demande de subvention dans le cadre d'accompagnement d'enfant à l'étranger"
    description "Ma super description"
    state 'draft'
    association :user, factory: [:user]

    before(:create) do |dossier, _evaluator|
      unless dossier.procedure
        procedure = create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ)
        dossier.procedure = procedure
      end
    end

    trait :with_entreprise do
      after(:build) do |dossier, _evaluator|
        etablissement = create(:etablissement)
        entreprise = create(:entreprise, etablissement: etablissement)
        dossier.entreprise = entreprise
        dossier.etablissement = etablissement
      end
    end

    trait :with_two_quartier_prioritaires do
      after(:build) do |dossier, _evaluator|
        dossier.quartier_prioritaires << create(:quartier_prioritaire)
        dossier.quartier_prioritaires << create(:quartier_prioritaire)
      end
    end

    trait :with_two_cadastres do
      after(:build) do |dossier, _evaluator|
        dossier.cadastres << create(:cadastre)
        dossier.cadastres << create(:cadastre)
      end
    end

    trait :with_cerfa_upload do
      after(:build) do |dossier, _evaluator|

        dossier.cerfa << create(:cerfa)
      end
    end
  end
end
