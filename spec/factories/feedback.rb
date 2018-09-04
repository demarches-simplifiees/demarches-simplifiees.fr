FactoryBot.define do
  factory :feedback do
    rating { Feedback.ratings.fetch(:happy) }
  end
end
