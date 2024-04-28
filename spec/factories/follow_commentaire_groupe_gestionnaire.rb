# frozen_string_literal: true

FactoryBot.define do
  factory :follow_commentaire_groupe_gestionnaire do
    association :groupe_gestionnaire
    association :gestionnaire
  end
end
