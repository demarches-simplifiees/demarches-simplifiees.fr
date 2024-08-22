# frozen_string_literal: true

FactoryBot.define do
  factory :trusted_device_token do
    association :instructeur
  end
end
