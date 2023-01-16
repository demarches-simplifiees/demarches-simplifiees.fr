FactoryBot.define do
  factory :email_event do
    to { "user@email.com" }
    subject { "Thank you" }
    processed_at { Time.zone.now }
    status { "dispatched" }

    trait :dolist do
      add_attribute(:method) { "dolist" }
    end
  end
end
