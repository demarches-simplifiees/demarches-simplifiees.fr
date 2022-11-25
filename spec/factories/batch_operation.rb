FactoryBot.define do
  factory :batch_operation do
    transient do
      invalid_instructeur { nil }
    end

    trait :archiver do
      operation { BatchOperation.operations.fetch(:archiver) }
      after(:build) do |batch_operation, _evaluator|
        procedure = create(:simple_procedure, :published, instructeurs: [_evaluator.invalid_instructeur.presence || batch_operation.instructeur], administrateurs: [create(:administrateur)])
        batch_operation.dossiers = [
          create(:dossier, :with_individual, :accepte, procedure: procedure),
          create(:dossier, :with_individual, :refuse, procedure: procedure),
          create(:dossier, :with_individual, :sans_suite, procedure: procedure)
        ]
      end
    end
  end
end
