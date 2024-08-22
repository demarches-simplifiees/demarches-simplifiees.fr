# frozen_string_literal: true

FactoryBot.define do
  factory :experts_procedure do
    association :expert
    association :procedure
  end
end
