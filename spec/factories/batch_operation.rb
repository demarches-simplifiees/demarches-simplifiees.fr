FactoryBot.define do
  factory :batch_operation do
    transient do
      invalid_instructeur { nil }
    end

    association :instructeur

    trait :archiver do
      operation { BatchOperation.operations.fetch(:archiver) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur], administrateurs: [create(:administrateur)])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :accepte, procedure: procedure),
          create(:dossier, :with_individual, :refuse, procedure: procedure),
          create(:dossier, :with_individual, :sans_suite, procedure: procedure)
        ]
      end
    end

    trait :passer_en_instruction do
      operation { BatchOperation.operations.fetch(:passer_en_instruction) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur], administrateurs: [create(:administrateur)])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_construction, procedure: procedure),
          create(:dossier, :with_individual, :en_construction, procedure: procedure)
        ]
      end
    end

    trait :accepter do
      operation { BatchOperation.operations.fetch(:accepter) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur], administrateurs: [create(:administrateur)])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_instruction, procedure: procedure),
          create(:dossier, :with_individual, :en_instruction, procedure: procedure)
        ]
      end
    end

    trait :follow do
      operation { BatchOperation.operations.fetch(:follow) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur], administrateurs: [create(:administrateur)])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_instruction, procedure: procedure),
          create(:dossier, :with_individual, :en_construction, procedure: procedure)
        ]
      end
    end

    trait :unfollow do
      operation { BatchOperation.operations.fetch(:unfollow) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur], administrateurs: [create(:administrateur)])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :followed, :en_instruction, procedure: procedure),
          create(:dossier, :with_individual, :followed, :en_construction, procedure: procedure)
        ]
      end
    end

    trait :repasser_en_construction do
      operation { BatchOperation.operations.fetch(:repasser_en_construction) }
      after(:build) do |batch_operation, evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [evaluator.invalid_instructeur.presence || batch_operation.instructeur], administrateurs: [create(:administrateur)])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :en_instruction, procedure: procedure),
          create(:dossier, :with_individual, :en_instruction, procedure: procedure)
        ]
      end
    end
  end
end
