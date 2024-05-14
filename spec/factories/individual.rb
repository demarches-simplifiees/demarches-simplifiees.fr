# frozen_string_literal: true

FactoryBot.define do
  factory :individual do
    gender { 'M.' }
    nom { 'Julien' }
    prenom { 'Xavier' }
    birthdate { Date.new(1991, 11, 01) }
    association :dossier

    trait :empty do
      gender { nil }
      nom { nil }
      prenom { nil }
      birthdate { nil }
    end

    trait :with_notification do
      notification_method { :email }
      email { 'julien.xavier@test.com' }
    end

    trait :without_notification do
      notification_method { :no_notification }
    end
  end
end
