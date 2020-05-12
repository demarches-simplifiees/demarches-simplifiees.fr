FactoryBot.define do
  factory :archive do
    groupe_instructeurs { [association(:groupe_instructeur)] }

    trait :pending do
      status { 'pending' }
    end

    trait :generated do
      status { 'generated' }
    end
  end
end
