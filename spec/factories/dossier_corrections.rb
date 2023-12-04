FactoryBot.define do
  factory :dossier_correction do
    dossier
    commentaire { association :commentaire, dossier: dossier }
    reason { :incorrect }
    resolved_at { nil }

    trait :resolved do
      resolved_at { Time.zone.now }
    end
  end
end
