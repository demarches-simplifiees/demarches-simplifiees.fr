FactoryBot.define do
  factory :traitement do
    trait :accepte do
      process_expired { true }
      state { :accepte }
    end
  end
end
