FactoryBot.define do
  factory :dossier_resolution do
    dossier
    commentaire
    resolved_at { nil }

    trait :resolved do
      resolved_at { Time.zone.now }
    end
  end
end
