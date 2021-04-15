FactoryBot.define do
  factory :dossier do
    autorisation_donnees { true }
    state { Dossier.states.fetch(:brouillon) }
    association :user

    transient do
      procedure { nil }
    end

    after(:build) do |dossier, evaluator|
      if evaluator.procedure.present?
        procedure = evaluator.procedure
      else
        procedure = create(:procedure, :published, :with_type_de_champ, :with_type_de_champ_private)
      end

      dossier.revision = procedure.active_revision

      # Assign the procedure to the dossier through the groupe_instructeur
      if dossier.groupe_instructeur.nil?
        dossier.groupe_instructeur = procedure.defaut_groupe_instructeur
      end

      dossier.build_default_individual
    end

    trait :with_entreprise do
      after(:build) do |dossier, _evaluator|
        if dossier.procedure.for_individual?
          raise 'Inconsistent factory: attempting to create a dossier :with_entreprise on a procedure that is `for_individual?`'
        end
        etablissement = create(:etablissement, :with_exercices, :with_effectif_mensuel)
        dossier.etablissement = etablissement
      end
    end

    trait :with_service do
      after(:create) do |dossier, _evaluator|
        dossier.procedure.service = create(:service)
      end
    end

    trait :with_individual do
      after(:build) do |dossier, evaluator|
        # If the procedure was implicitely created by the factory,
        # mark it automatically as for_individual.
        if evaluator.procedure.nil?
          dossier.procedure.update(for_individual: true)
        end
        if !dossier.procedure.for_individual?
          raise 'Inconsistent factory: attempting to create a dossier :with_individual on a procedure that is not `for_individual?`'
        end
        dossier.individual = build(:individual, dossier: dossier)
      end
    end

    trait :archived do
      archived { true }
    end

    trait :not_archived do
      archived { false }
    end

    trait :discarded do
      hidden_at { Time.zone.now }
    end

    trait :with_dossier_link do
      after(:create) do |dossier, _evaluator|
        # create linked dossier
        linked_dossier = create(:dossier, :en_construction)

        # find first type de champ dossier_link
        type_de_champ = dossier.types_de_champ.find do |t|
          t.type_champ == TypeDeChamp.type_champs.fetch(:dossier_link)
        end

        # if type de champ does not exist create it
        if !type_de_champ
          type_de_champ = create(:type_de_champ_dossier_link, procedure: dossier.procedure)
        end

        # find champ with the type de champ
        champ = dossier.reload.champs.find do |c|
          c.type_de_champ == type_de_champ
        end

        # if champ does not exist create it
        if !champ
          champ = create(:champ_dossier_link, dossier: dossier, type_de_champ: type_de_champ)
        end

        # set champ value with linked dossier
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
        g = create(:instructeur)
        g.followed_dossiers << dossier
      end
    end

    trait :brouillon do
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
      transient do
        motivation { nil }
        processed_at { nil }
      end

      after(:create) do |dossier, evaluator|
        dossier.state = Dossier.states.fetch(:accepte)
        processed_at = evaluator.processed_at
        if processed_at.present?
          dossier.en_construction_at ||= processed_at - 2.minutes
          dossier.en_instruction_at ||= processed_at - 1.minute
          dossier.traitements.build(state: Dossier.states.fetch(:accepte), processed_at: processed_at, motivation: evaluator.motivation)
        else
          dossier.en_construction_at ||= dossier.created_at + 1.minute
          dossier.en_instruction_at ||= dossier.en_construction_at + 1.minute
          dossier.traitements.build(state: Dossier.states.fetch(:accepte), processed_at: dossier.en_instruction_at + 1.minute, motivation: evaluator.motivation)
        end
        dossier.save!
      end
    end

    trait :refuse do
      after(:create) do |dossier, _evaluator|
        dossier.state = Dossier.states.fetch(:refuse)
        dossier.en_construction_at ||= dossier.created_at + 1.minute
        dossier.en_instruction_at ||= dossier.en_construction_at + 1.minute
        dossier.traitements.build(state: Dossier.states.fetch(:refuse), processed_at: dossier.en_instruction_at + 1.minute)
        dossier.save!
      end
    end

    trait :sans_suite do
      after(:create) do |dossier, _evaluator|
        dossier.state = Dossier.states.fetch(:sans_suite)
        dossier.en_construction_at ||= dossier.created_at + 1.minute
        dossier.en_instruction_at ||= dossier.en_construction_at + 1.minute
        dossier.traitements.build(state: Dossier.states.fetch(:sans_suite), processed_at: dossier.en_instruction_at + 1.minute)
        dossier.save!
      end
    end

    trait :with_motivation do
      after(:create) do |dossier, _evaluator|
        motivation = case dossier.state
        when Dossier.states.fetch(:refuse)
          'L’entreprise concernée n’est pas agréée.'
        when Dossier.states.fetch(:sans_suite)
          'Le département n’est pas éligible. Veuillez remplir un nouveau dossier auprès de la DDT du 93.'
        else
          'Vous avez validé les conditions.'
        end
        dossier.traitements.last.update!(motivation: motivation)
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

    trait :with_justificatif do
      after(:create) do |dossier, _evaluator|
        dossier.justificatif_motivation.attach(
          io: StringIO.new('Hello World'),
          filename: 'hello.txt'
        )
      end
    end

    trait :with_all_champs do
      after(:create) do |dossier, _evaluator|
        dossier.champs = dossier.types_de_champ.map do |type_de_champ|
          build(:"champ_#{type_de_champ.type_champ}", dossier: dossier, type_de_champ: type_de_champ)
        end
        dossier.save!
      end
    end

    trait :with_all_annotations do
      after(:create) do |dossier, _evaluator|
        dossier.champs_private = dossier.types_de_champ_private.map do |type_de_champ|
          build(:"champ_#{type_de_champ.type_champ}", private: true, dossier: dossier, type_de_champ: type_de_champ)
        end
        dossier.save!
      end
    end
  end
end
