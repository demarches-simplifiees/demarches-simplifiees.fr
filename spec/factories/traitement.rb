# frozen_string_literal: true

FactoryBot.define do
  factory :traitement do
    trait :accepte do
      state { :accepte }
    end
  end
end
