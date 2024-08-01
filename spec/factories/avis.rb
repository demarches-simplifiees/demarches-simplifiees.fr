# frozen_string_literal: true

FactoryBot.define do
  sequence(:expert_email) { |n| "expert#{n}@expert.com" }

  factory :avis do
    email { generate(:expert_email) }
    introduction { 'Bonjour, merci de me donner votre avis sur ce dossier' }
    confidentiel { false }

    association :dossier
    association :claimant, factory: :instructeur

    after(:build) do |avis, _evaluator|
      avis.experts_procedure ||= build(:experts_procedure, procedure: avis.dossier.procedure)
    end

    trait :confidentiel do
      confidentiel { true }
    end

    trait :not_confidentiel do
      confidentiel { false }
    end

    trait :with_instructeur do
      email { nil }
      instructeur { association :instructeur, email: generate(:expert_email) }
    end

    trait :with_answer do
      answer { "Mon avis se décompose en deux points :\n- La demande semble pertinente\n- Le demandeur remplit les conditions." }
    end

    trait :with_introduction do
      introduction_file { Rack::Test::UploadedFile.new('spec/fixtures/files/white.png', 'image/png') }
    end

    trait :with_piece_justificative do
      piece_justificative_file { Rack::Test::UploadedFile.new('spec/fixtures/files/white.png', 'image/png') }
    end
  end
end
