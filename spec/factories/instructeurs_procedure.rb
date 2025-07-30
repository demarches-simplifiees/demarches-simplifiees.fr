# frozen_string_literal: true

FactoryBot.define do
  factory :instructeurs_procedure do
    association :instructeur
    association :procedure

    position { 1 }
  end
end
