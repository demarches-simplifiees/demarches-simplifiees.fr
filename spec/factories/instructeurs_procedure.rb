# frozen_string_literal: true

FactoryBot.define do
  factory :instructeurs_procedure do
    association :instructeur
    association :procedure
  end
end
