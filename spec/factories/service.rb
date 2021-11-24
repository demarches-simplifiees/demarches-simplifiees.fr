FactoryBot.define do
  factory :service do
    sequence(:nom) { |n| "Service #{n}" }
    organisme { 'organisme' }
    type_organisme { Service.type_organismes.fetch(:association) }
    email { 'email@toto.com' }
    telephone { '1234' }
    horaires { 'de 9 h à 18 h' }
    adresse { 'adresse' }

    association :administrateur
  end
end
