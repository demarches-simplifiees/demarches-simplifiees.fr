FactoryBot.define do
  sequence(:expert_email) { |n| "expert#{n}@expert.com" }

  factory :avis do
    email { generate(:expert_email) }
    introduction { 'Bonjour, merci de me donner votre avis sur ce dossier' }
    confidentiel { false }

    association :dossier
    association :claimant, factory: :instructeur

    trait :with_instructeur do
      email { nil }
      instructeur { association :instructeur, email: generate(:expert_email) }
    end

    trait :with_answer do
      answer { "Mon avis se décompose en deux points :\n- La demande semble pertinente\n- Le demandeur remplit les conditions." }
    end
  end
end
