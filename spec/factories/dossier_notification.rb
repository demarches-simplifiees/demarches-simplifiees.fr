# frozen_string_literal: true

FactoryBot.define do
  factory :dossier_notification do
    dossier { association :dossier }
    instructeur { association :instructeur }
    notification_type { "dossier_depose" }
    display_at { 1.day.ago }
  end
end
