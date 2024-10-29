# frozen_string_literal: true

FactoryBot.define do
  factory :label do
    name { 'Un label' }
    color { 'green-bourgeon' }
    association :procedure
  end
end
