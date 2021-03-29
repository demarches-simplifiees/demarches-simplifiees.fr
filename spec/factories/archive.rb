FactoryBot.define do
  factory :archive do
    content_type { 'everything' }
    groupe_instructeurs { [association(:groupe_instructeur)] }

    trait :pending do
      status { 'pending' }
    end

    trait :generated do
      status { 'generated' }
    end
  end
end
