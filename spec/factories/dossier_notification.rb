# frozen_string_literal: true

FactoryBot.define do
  factory :dossier_notification do
    dossier { association :dossier }
    notification_type { "dossier_depose" }
    display_at { 1.day.ago }

    trait :for_groupe_instructeur do
      groupe_instructeur { association :groupe_instructeur }
      instructeur { nil }
    end

    trait :for_instructeur do
      instructeur { association :instructeur }
      groupe_instructeur { nil }
    end
  end
end
