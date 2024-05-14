# frozen_string_literal: true

FactoryBot.define do
  factory :archive do
    time_span_type { 'everything' }
    groupe_instructeurs { [association(:groupe_instructeur)] }
    key { 'unique-key' }

    trait :pending do
      job_status { 'pending' }
    end

    trait :generated do
      job_status { 'generated' }
    end
  end
end
