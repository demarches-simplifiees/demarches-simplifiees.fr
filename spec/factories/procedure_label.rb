# frozen_string_literal: true

FactoryBot.define do
  factory :procedure_label do
    name { 'Un label' }
    color { 'green-bourgeon' }
    association :procedure
  end
end
