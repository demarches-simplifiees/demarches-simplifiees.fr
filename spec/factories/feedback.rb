FactoryBot.define do
  factory :feedback do
    rating { Feedback.ratings.fetch(:happy) }

    trait :happy do
      rating { Feedback.ratings.fetch(:happy) }
    end

    trait :neutral do
      rating { Feedback.ratings.fetch(:neutral) }
    end

    trait :unhappy do
      rating { Feedback.ratings.fetch(:unhappy) }
    end
  end
end
