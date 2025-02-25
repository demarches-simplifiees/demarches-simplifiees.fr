# frozen_string_literal: true

FactoryBot.define do
  sequence(:unique_from_path) { |n| "source-path#{n}" }

  factory :path_rewrite do
    from { generate(:unique_from_path) }
    to { "destination-path" }
  end
end
