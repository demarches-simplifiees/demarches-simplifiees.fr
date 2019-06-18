FactoryBot.define do
  factory :dossier do
    autorisation_donnees { true }
    state { Dossier.states.fetch(:brouillon) }
    association :user, factory: [:user]

    before(:create) do |dossier, _evaluator|
      if !dossier.procedure
        procedure = create(:procedure, :published, :with_two_type_de_piece_justificative, :with_type_de_champ, :with_type_de_champ_private)
        dossier.procedure = procedure
      end
    end

    trait :with_entreprise do
      after(:build) do |dossier, _evaluator|
        etablissement = create(:etablissement)
        dossier.etablissement = etablissement
      end
    end

    trait :with_service do
      after(:create) do |dossier, _evaluator|
        dossier.procedure.service = create(:service)
      end
    end

    trait :for_individual do
      after(:build) do |dossier, _evaluator|
        dossier.individual = create(:individual)
        dossier.save
      end
    end

    trait :archived do
      archived { true }
    end

    trait :not_archived do
      archived { false }
    end

    trait :hidden do
      hidden_at { Time.zone.now }
    end

    trait :with_dossier_link do
      after(:create) do |dossier, _evaluator|
        linked_dossier = create(:dossier)
        type_de_champ = dossier.procedure.types_de_champ.find { |t| t.type_champ == TypeDeChamp.type_champs.fetch(:dossier_link) }
        champ = dossier.champs.find { |c| c.type_de_champ == type_de_champ }

        champ.value = linked_dossier.id
        champ.save!
      end
    end

    trait :with_commentaires do
      after(:create) do |dossier, _evaluator|
        dossier.commentaires += create_list(:commentaire, 2)
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
        dossier.state = Dossier.states.fetch(:en_construction)
        dossier.en_construction_at ||= dossier.created_at + 1.minute
        dossier.save!
      end
    end

    trait :en_instruction do
      after(:create) do |dossier, _evaluator|
        dossier.state = Dossier.states.fetch(:en_instruction)
        dossier.en_construction_at ||= dossier.created_at + 1.minute
        dossier.en_instruction_at ||= dossier.en_construction_at + 1.minute
        dossier.save!
      end
    end

    trait :accepte do
      after(:create) do |dossier, _evaluator|
        dossier.state = Dossier.states.fetch(:accepte)
        dossier.en_construction_at ||= dossier.created_at + 1.minute
        dossier.en_instruction_at ||= dossier.en_construction_at + 1.minute
        dossier.processed_at ||= dossier.en_instruction_at + 1.minute
        dossier.save!
      end
    end

    trait :refuse do
      after(:create) do |dossier, _evaluator|
        dossier.state = Dossier.states.fetch(:refuse)
        dossier.en_construction_at ||= dossier.created_at + 1.minute
        dossier.en_instruction_at ||= dossier.en_construction_at + 1.minute
        dossier.processed_at ||= dossier.en_instruction_at + 1.minute
        dossier.save!
      end
    end

    trait :sans_suite do
      after(:create) do |dossier, _evaluator|
        dossier.state = Dossier.states.fetch(:sans_suite)
        dossier.en_construction_at ||= dossier.created_at + 1.minute
        dossier.en_instruction_at ||= dossier.en_construction_at + 1.minute
        dossier.processed_at ||= dossier.en_instruction_at + 1.minute
        dossier.save!
      end
    end

    trait :with_motivation do
      after(:create) do |dossier, _evaluator|
        dossier.motivation = case dossier.state
        when Dossier.states.fetch(:refuse)
          'L’entreprise concernée n’est pas agréée.'
        when Dossier.states.fetch(:sans_suite)
          'Le département n’est pas éligible. Veuillez remplir un nouveau dossier auprès de la DDT du 93.'
        else
          'Vous avez validé les conditions.'
        end
      end
    end

    trait :with_attestation do
      after(:create) do |dossier, _evaluator|
        if dossier.procedure.attestation_template.blank?
          dossier.procedure.attestation_template = create(:attestation_template)
        end
        dossier.attestation = dossier.build_attestation
      end
    end

    trait :with_all_champs do
      after(:create) do |dossier, _evaluator|
        dossier.champs = dossier.procedure.types_de_champ.map do |type_de_champ|
          build(:"champ_#{type_de_champ.type_champ}", type_de_champ: type_de_champ)
        end
        dossier.save!
      end
    end

    trait :with_all_annotations do
      after(:create) do |dossier, _evaluator|
        dossier.champs = dossier.procedure.types_de_champ.map do |type_de_champ|
          build(:"champ_#{type_de_champ.type_champ}", type_de_champ: type_de_champ)
        end
        dossier.save!
      end
    end
  end
end
