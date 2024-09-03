# frozen_string_literal: true

FactoryBot.define do
  sequence(:gestionnaire_email) { |n| "gestionnaire#{n}@demarches-simplifiees.fr" }

  factory :gestionnaire do
    user { association :user, email: email, password: password }

    transient do
      email { generate(:gestionnaire_email) }
      password { '{My-$3cure-p4ssWord}' }
    end
  end
end
