# frozen_string_literal: true

FactoryBot.define do
  sequence(:groupe_label) { |n| "label_#{n}" }

  factory :groupe_instructeur do
    label { generate(:groupe_label) }
    association :procedure

    after(:create) do |groupe_instructeur, _evaluator|
      groupe_instructeur.procedure.toggle_routing
    end

    trait :default do
      label { GroupeInstructeur::DEFAUT_LABEL }
    end
  end
end
