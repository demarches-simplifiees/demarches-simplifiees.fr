FactoryBot.define do
  sequence(:instructeur_email) { |n| "inst#{n}@inst.com" }

  factory :instructeur do
    transient do
      email { generate(:instructeur_email) }
      password { 'somethingverycomplated!' }
    end

    initialize_with do
      User.create_or_promote_to_instructeur(email, password).instructeur
    end
  end
end
