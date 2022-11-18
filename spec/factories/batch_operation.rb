FactoryBot.define do
  factory :batch_operation do
    trait :archiver do
      operation { BatchOperation.operations.fetch(:archiver) }
      dossiers do
        [
          association(:dossier, :accepte),
          association(:dossier, :refuse),
          association(:dossier, :sans_suite)
        ]
      end
    end
  end
end
