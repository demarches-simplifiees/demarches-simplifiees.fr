FactoryBot.define do
  sequence(:instructeur_email) { |n| "inst#{n}@inst.com" }

  factory :instructeur do
    user { association :user, email: email, password: password }

    transient do
      email { generate(:instructeur_email) }
      password { 'somethingverycomplated!' }
    end
  end
end
