# frozen_string_literal: true

FactoryBot.define do
  factory :deleted_dossier do
    dossier_id  { 1111 }
    state       { Dossier.states.fetch(:en_construction) }
    reason      { DeletedDossier.reasons.fetch(:user_request) }
    deleted_at  { Time.zone.now }

    association :procedure, :published

    transient do
      dossier { nil }
    end

    after(:build) do |deleted_dossier, evaluator|
      if evaluator.dossier
        deleted_dossier.dossier_id = evaluator.dossier.id
        deleted_dossier.state = evaluator.dossier.state
        deleted_dossier.procedure = evaluator.dossier.procedure
      end
    end
  end
end
