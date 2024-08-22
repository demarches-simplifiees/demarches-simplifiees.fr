# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_message do
    body { 'bonjour' }
    dossier_count { 1 }
    dossier_state { Dossier.states.fetch(:brouillon) }
    sent_at { 1.day.ago }
    instructeur { association :instructeur }
    procedure { association :procedure }
  end
end
