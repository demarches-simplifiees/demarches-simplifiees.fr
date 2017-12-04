FactoryGirl.define do
  factory :dossier do
    state 'brouillon'
    association :user, factory: [:user]

    before(:create) do |dossier, _evaluator|
      unless dossier.procedure
        procedure = create(:procedure, :published, :with_two_type_de_piece_justificative, :with_type_de_champ, :with_type_de_champ_private)
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

    trait :for_individual do
      after(:build) do |dossier, _evaluator|
        dossier.individual = create :individual
        dossier.save
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

    trait :archived do
      archived true
    end

    trait :not_archived do
      archived false
    end

    trait :with_dossier_link do
      after(:create) do |dossier, _evaluator|
        linked_dossier = create(:dossier)
        type_de_champ = dossier.procedure.types_de_champ.find { |t| t.type_champ == 'dossier_link' }
        champ = dossier.champs.find { |c| c.type_de_champ == type_de_champ }

        champ.value = linked_dossier.id
        champ.save!
      end
    end

    trait :followed do
      after(:create) do |dossier, _evaluator|
        g = create(:gestionnaire)
        g.followed_dossiers << dossier
      end
    end

    trait :en_construction do
      after(:create) do |dossier, _evaluator|
        dossier.state = 'en_construction'
        dossier.en_construction_at = dossier.created_at + 1.minute
        dossier.save!
      end
    end

    trait :received do
      after(:create) do |dossier, _evaluator|
        dossier.state = 'received'
        dossier.en_construction_at = dossier.created_at + 1.minute
        dossier.created_at = dossier.created_at + 2.minute
        dossier.save!
      end
    end
  end
end
