FactoryBot.define do
  sequence(:gestionnaire_email) { |n| "gestionnaire#{n}@demarches-simplifiees.fr" }

  factory :gestionnaire do
    user { association :user, email: email, password: password }

    transient do
      email { generate(:gestionnaire_email) }
      password { 'somethingverycomplated!' }
    end
  end
end
