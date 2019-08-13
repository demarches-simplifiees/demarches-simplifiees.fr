FactoryBot.define do
  sequence(:instructeur_email) { |n| "inst#{n}@inst.com" }

  factory :instructeur do
    email { generate(:instructeur_email) }

    transient do
      password { 'somethingverycomplated!' }
    end

    after(:create) do |instructeur, evaluator|
      if evaluator.user.present?
        user = evaluator.user
      else
        user = create(:user, email: instructeur.email, password: evaluator.password)
      end

      instructeur.update!(user: user)
    end
  end
end
