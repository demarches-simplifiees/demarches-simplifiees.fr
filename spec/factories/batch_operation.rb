FactoryBot.define do
  factory :batch_operation do
    transient do
      invalid_instructeur { nil }
    end
    trait :archiver do
      operation { BatchOperation.operations.fetch(:archiver) }
      after(:build) do |batch_operation, _evaluator|
        procedure = create(:procedure, instructeurs: [_evaluator.invalid_instructeur.presence || batch_operation.instructeur])
        batch_operation.dossiers = [
          build(:dossier, :accepte, procedure: procedure),
          build(:dossier, :refuse, procedure: procedure),
          build(:dossier, :sans_suite, procedure: procedure)
        ]
      end
    end
  end
end
