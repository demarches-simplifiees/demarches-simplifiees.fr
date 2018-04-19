FactoryBot.define do
  factory :service do
    nom 'service'
    type_organisme 'commune'
    administrateur { create(:administrateur) }
  end
end
