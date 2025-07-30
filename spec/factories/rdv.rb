# frozen_string_literal: true

FactoryBot.define do
  factory :rdv do
    starts_at { Time.zone.parse("2025-02-14 10:00:00") }
    rdv_plan_external_id { "1234567890" }
    dossier { create(:dossier) }
    instructeur { dossier.groupe_instructeur.instructeurs.first }

    trait :booked do
      rdv_external_id { "2345678901" }
    end
  end
end
