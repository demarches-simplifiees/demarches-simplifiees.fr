# frozen_string_literal: true

FactoryBot.define do
  sequence(:procedure_path) { |n| "fake_path#{n}" }

  factory :procedure_path do
    path { generate(:procedure_path) }
  end
end
