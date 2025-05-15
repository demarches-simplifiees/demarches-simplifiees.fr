FactoryBot.define do
  factory :batch_operation do
    transient do
      invalid_instructeur { nil }
    end

    association :instructeur

    trait :archiver do
      operation { BatchOperation.operations.fetch(:archiver) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :accepte, procedure: procedure),
          create(:dossier, :with_individual, :refuse, procedure: procedure),
          create(:dossier, :with_individual, :sans_suite, procedure: procedure)
        ]
      end
    end

    trait :desarchiver do
      operation { BatchOperation.operations.fetch(:desarchiver) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :accepte, procedure: procedure, archived: true),
          create(:dossier, :with_individual, :refuse, procedure: procedure, archived: true),
          create(:dossier, :with_individual, :sans_suite, procedure: procedure, archived: true)
        ]
      end
    end

    trait :passer_en_instruction do
      operation { BatchOperation.operations.fetch(:passer_en_instruction) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_construction, procedure: procedure),
          create(:dossier, :with_individual, :en_construction, procedure: procedure)
        ]
      end
    end

    trait :repousser_expiration do
      operation { BatchOperation.operations.fetch(:repousser_expiration) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :accepte, procedure: procedure, processed_at: 12.months.ago),
          create(:dossier, :with_individual, :accepte, procedure: procedure, processed_at: 12.months.ago)
        ]
      end
    end

    trait :accepter do
      operation { BatchOperation.operations.fetch(:accepter) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_instruction, procedure: procedure),
          create(:dossier, :with_individual, :en_instruction, procedure: procedure)
        ]
      end
    end

    trait :refuser do
      operation { BatchOperation.operations.fetch(:refuser) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_instruction, procedure: procedure),
          create(:dossier, :with_individual, :en_instruction, procedure: procedure)
        ]
      end
    end

    trait :classer_sans_suite do
      operation { BatchOperation.operations.fetch(:classer_sans_suite) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_instruction, procedure: procedure),
          create(:dossier, :with_individual, :en_instruction, procedure: procedure)
        ]
      end
    end

    trait :follow do
      operation { BatchOperation.operations.fetch(:follow) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_instruction, procedure: procedure),
          create(:dossier, :with_individual, :en_construction, procedure: procedure)
        ]
      end
    end

    trait :unfollow do
      operation { BatchOperation.operations.fetch(:unfollow) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_instruction, procedure: procedure, followers_instructeurs: procedure.instructeurs),
          create(:dossier, :with_individual, :en_construction, procedure: procedure, followers_instructeurs: procedure.instructeurs)
        ]
      end
    end

    trait :restaurer do
      operation { BatchOperation.operations.fetch(:restaurer) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :accepte, procedure: procedure, hidden_by_administration_at: Time.zone.now),
          create(:dossier, :with_individual, :refuse, procedure: procedure, hidden_by_administration_at: Time.zone.now)
        ]
      end
    end

    trait :repasser_en_construction do
      operation { BatchOperation.operations.fetch(:repasser_en_construction) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_instruction, procedure: procedure),
          create(:dossier, :with_individual, :en_instruction, procedure: procedure)
        ]
      end
    end

    trait :supprimer do
      operation { BatchOperation.operations.fetch(:supprimer) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :accepte, procedure: procedure),
          create(:dossier, :with_individual, :refuse, procedure: procedure)
        ]
      end
    end
  end
end
