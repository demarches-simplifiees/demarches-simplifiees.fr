FactoryBot.define do
  factory :deleted_dossier do
    dossier_id  { 1111 }
    state       { Dossier.states.fetch(:en_construction) }
    reason      { DeletedDossier.reasons.fetch(:user_request) }
    deleted_at  { Time.zone.now }

    association :procedure, :published
  end
end
