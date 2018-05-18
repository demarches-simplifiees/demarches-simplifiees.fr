FactoryBot.define do
  factory :service do
    nom 'service'
    organisme 'organisme'
    type_organisme 'commune'
    administrateur { create(:administrateur) }
    email 'email@toto.com'
    telephone '1234'
    horaires 'de 9 h à 18 h'
    adresse 'adresse'
  end
end
