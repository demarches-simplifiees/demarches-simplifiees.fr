FactoryBot.define do
  factory :archive do
    time_span_type { 'everything' }
    groupe_instructeurs { [association(:groupe_instructeur)] }
    key { 'unique-key' }

    trait :pending do
      status { 'pending' }
    end

    trait :generated do
      status { 'generated' }
    end
  end
end
