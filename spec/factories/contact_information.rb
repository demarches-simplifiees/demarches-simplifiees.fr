# frozen_string_literal: true

FactoryBot.define do
  factory :contact_information do
    sequence(:nom) { |n| "Service #{n}" }
    email { 'email@toto.com' }
    telephone { '1234' }
    horaires { 'de 9 h à 18 h' }
    adresse { 'adresse' }

    association :groupe_instructeur
  end
end
