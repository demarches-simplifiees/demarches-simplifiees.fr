# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    sequence(:nom) { |n| "Service #{n}" }
    organisme { 'organisme' }
    type_organisme { Service.type_organismes.fetch(:association) }
    email { 'email@toto.com' }
    telephone { '1234' }
    horaires { 'de 9 h à 18 h' }
    adresse { 'adresse' }
    siret { '35600082800018' }
    etablissement_infos { { adresse: "75 rue du Louvre\n75002\nPARIS\nFRANCE" } }
    etablissement_lat { 48.87 }
    etablissement_lng { 2.34 }

    association :administrateur
  end
end
