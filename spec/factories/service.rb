# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    sequence(:nom) { |n| "Service #{n}" }
    organisme { 'organisme' }
    type_organisme { Service.type_organismes.fetch(:association) }
    email { 'email@toto.com' }
    link { nil }
    telephone { '1234' }
    horaires { 'de 9 h à 18 h' }
    adresse { 'adresse' }
    siret { '35600011719156' }
    etablissement_infos { { "adresse" => "75 rue du Louvre\n75002\nPARIS\nFRANCE" } }
    etablissement_lat { 48.87 }
    etablissement_lng { 2.34 }

    trait :with_link do
      email { nil }
      link { 'https://example.com/contact' }
    end

    trait :with_both_contacts do
      email { 'email@toto.com' }
      link { 'https://example.com/contact' }
    end

    association :administrateur
  end
end
