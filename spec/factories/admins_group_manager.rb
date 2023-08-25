FactoryBot.define do
  sequence(:admins_group_manager_email) { |n| "admins_group_manager#{n}@demarches-simplifiees.fr" }

  factory :admins_group_manager do
    user { association :user, email: email, password: password }

    transient do
      email { generate(:admins_group_manager_email) }
      password { 'somethingverycomplated!' }
    end
  end
end
