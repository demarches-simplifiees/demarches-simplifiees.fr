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

    trait :with_two_quartier_prioritaires do
      after(:build) do |dossier, _evaluator|

        qp1 = create(:quartier_prioritaire)
        qp2 = create(:quartier_prioritaire)

        dossier.quartier_prioritaires << qp1
        dossier.quartier_prioritaires << qp2
      end
    end

    trait :with_two_cadastres do
      after(:build) do |dossier, _evaluator|

        qp1 = create(:cadastre)
        qp2 = create(:cadastre)

        dossier.cadastres << qp1
        dossier.cadastres << qp2
      end
    end
  end
end
