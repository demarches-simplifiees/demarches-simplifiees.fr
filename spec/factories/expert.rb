FactoryBot.define do
  sequence(:create_expert_email) { |n| "expert#{n}@expert.com" }

  factory :expert do
    transient do
      email { generate(:expert_email) }
      password { 'somethingverycomplated!' }
    end

    initialize_with do
      User.create_or_promote_to_expert(email, password).expert
    end
  end
end
