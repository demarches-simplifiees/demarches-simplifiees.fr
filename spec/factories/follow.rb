# frozen_string_literal: true

FactoryBot.define do
  factory :follow do
    association :instructeur
    association :dossier
  end
end
