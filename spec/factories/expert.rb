FactoryBot.define do
  sequence(:create_expert_email) { |n| "expert#{n}@expert.com" }

  factory :expert do
    user { association :user, email: email, password: password }

    transient do
      email { generate(:expert_email) }
      password { 'somethingverycomplated!' }
    end
  end
end
