FactoryBot.define do
  factory :dossier do
    autorisation_donnees { true }
    state { Dossier.states.fetch(:brouillon) }

    user { association :user }
    groupe_instructeur { procedure.routing_enabled? ? nil : procedure.defaut_groupe_instructeur }
    revision { procedure.active_revision }
    individual { association(:individual, :empty, dossier: instance, strategy: :build) if procedure.for_individual? }

    transient do
      for_individual? { false }
      # For now a dossier must use a `create`d procedure, even if the dossier is only built (and not created).
      # This is because saving the dossier fails when the procedure has not been saved beforehand
      # (due to some internal ActiveRecord error).
      # TODO: find a way to find the issue and just `build` the procedure.
      procedure { create(:procedure, :published, :with_type_de_champ, :with_type_de_champ_private, for_individual: for_individual?) }
    end

    trait :with_entreprise do
      transient do
        as_degraded_mode { false }
      end

      after(:build) do |dossier, evaluator|
        if dossier.procedure.for_individual?
          raise 'Inconsistent factory: attempting to create a dossier :with_entreprise on a procedure that is `for_individual?`'
        end

        etablissement = if evaluator.as_degraded_mode
          Etablissement.new(siret: build(:etablissement).siret)
        else
          create(:etablissement, :with_exercices, :with_effectif_mensuel)
        end

        dossier.update(etablissement:)
      end
    end

    trait :with_service do
      after(:create) do |dossier, _evaluator|
        dossier.procedure.service = create(:service)
      end
    end

    trait :for_tiers_with_notification do
      for_tiers { true }
      mandataire_first_name { 'John' }
      mandataire_last_name { 'Doe' }

      transient do
        for_individual? { true }
      end

      after(:build) do |dossier, _evaluator|
        if !dossier.procedure.for_individual?
          raise 'Inconsistent factory: attempting to create a dossier :with_individual on a procedure that is not `for_individual?`'
        end
        dossier.individual = build(:individual, :with_notification, dossier: dossier)
      end
    end

    trait :for_tiers_without_notification do
      for_tiers { true }
      mandataire_first_name { 'John' }
      mandataire_last_name { 'Doe' }

      transient do
        for_individual? { true }
      end

      after(:build) do |dossier, _evaluator|
        if !dossier.procedure.for_individual?
          raise 'Inconsistent factory: attempting to create a dossier :with_individual on a procedure that is not `for_individual?`'
        end
        dossier.individual = build(:individual, :without_notification, dossier: dossier)
      end
    end

    trait :with_individual do
      transient do
        for_individual? { true }
      end

      after(:build) do |dossier, _evaluator|
        if !dossier.procedure.for_individual?
          raise 'Inconsistent factory: attempting to create a dossier :with_individual on a procedure that is not `for_individual?`'
        end
        dossier.individual = build(:individual, dossier: dossier)
      end
    end

    trait :with_declarative_accepte do
      after(:build) do |dossier, _evaluator|
        dossier.procedure.declarative_with_state = 'accepte'
      end
    end

    trait :with_declarative_en_instruction do
      after(:build) do |dossier, _evaluator|
        dossier.procedure.declarative_with_state = 'en_instruction'
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

    trait :hidden_by_administration do
      hidden_by_administration_at { 1.day.ago }
      hidden_by_reason { DeletedDossier.reasons.fetch(:instructeur_request) }
    end

    trait :with_commentaires do
      commentaires { [build(:commentaire), build(:commentaire)] }
    end

    trait :with_invites do
      invites { [build(:invite)] }
    end

    trait :with_avis do
      avis { [build(:avis)] }
    end

    trait :with_dossier_operation_logs do
      dossier_operation_logs { [build(:dossier_operation_log)] }
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
        dossier.groupe_instructeur ||= dossier.procedure&.defaut_groupe_instructeur

        processed_at = DossierWithReferenceDate.assign(dossier)
        dossier.traitements.passer_en_construction(processed_at:)

        dossier.save!
      end
    end

    trait :en_instruction do
      after(:create) do |dossier, _evaluator|
        dossier.state = Dossier.states.fetch(:en_instruction)
        dossier.groupe_instructeur ||= dossier.procedure&.defaut_groupe_instructeur

        processed_at = DossierWithReferenceDate.assign(dossier)
        dossier.traitements.passer_en_instruction(processed_at:)

        dossier.save!
      end
    end

    trait :accepte do
      transient do
        motivation { nil }
      end

      after(:create) do |dossier, evaluator|
        dossier.state = Dossier.states.fetch(:accepte)
        dossier.groupe_instructeur ||= dossier.procedure&.defaut_groupe_instructeur

        processed_at = DossierWithReferenceDate.assign(dossier)
        dossier.traitements.accepter(motivation: evaluator.motivation, processed_at:)

        dossier.save!
      end
    end

    trait :refuse do
      transient do
        motivation { nil }
      end

      after(:create) do |dossier, evaluator|
        dossier.state = Dossier.states.fetch(:refuse)
        dossier.groupe_instructeur ||= dossier.procedure&.defaut_groupe_instructeur

        processed_at = DossierWithReferenceDate.assign(dossier)
        dossier.traitements.refuser(motivation: evaluator.motivation, processed_at:)

        dossier.save!
      end
    end

    trait :sans_suite do
      transient do
        motivation { nil }
      end

      after(:create) do |dossier, evaluator|
        dossier.state = Dossier.states.fetch(:sans_suite)
        dossier.groupe_instructeur ||= dossier.procedure&.defaut_groupe_instructeur

        processed_at = DossierWithReferenceDate.assign(dossier)
        dossier.traitements.classer_sans_suite(motivation: evaluator.motivation, processed_at:)

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
      after(:build) do |dossier, _evaluator|
        dossier.procedure.attestation_template ||= build(:attestation_template)
        dossier.association(:attestation_template).target = dossier.procedure.attestation_template
        dossier.attestation = dossier.build_attestation
      end
    end

    trait :with_justificatif do
      after(:create) do |dossier, _evaluator|
        dossier.justificatif_motivation.attach(
          io: StringIO.new('Hello World'),
          filename: 'hello.txt',
          # we don't want to run virus scanner on this file
          metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
        )
      end
    end

    trait :with_populated_champs do
      after(:create) do |dossier, _evaluator|
        dossier.champs_to_destroy.where(private: false).destroy_all
        dossier.types_de_champ.each do |type_de_champ|
          value = if type_de_champ.simple_drop_down_list?
            type_de_champ.drop_down_list_enabled_non_empty_options.first
          elsif type_de_champ.multiple_drop_down_list?
            type_de_champ.drop_down_list_enabled_non_empty_options.first(2).to_json
          end
          attrs = { stable_id: type_de_champ.stable_id, dossier:, type_de_champ:, value: }.compact
          create(:"champ_do_not_use_#{type_de_champ.type_champ}", **attrs)
        end
        dossier.reload
      end
    end

    trait :with_populated_annotations do
      after(:create) do |dossier, _evaluator|
        dossier.champs_to_destroy.where(private: true).destroy_all
        dossier.types_de_champ_private.each do |type_de_champ|
          value = if type_de_champ.simple_drop_down_list?
            type_de_champ.drop_down_list_enabled_non_empty_options.first
          elsif type_de_champ.multiple_drop_down_list?
            type_de_champ.drop_down_list_enabled_non_empty_options.first(2).to_json
          end
          attrs = { stable_id: type_de_champ.stable_id, dossier:, private: true, type_de_champ:, value: }.compact
          create(:"champ_do_not_use_#{type_de_champ.type_champ}", **attrs)
        end
        dossier.reload
      end
    end

    trait :prefilled do
      prefilled { true }
    end
  end
end
