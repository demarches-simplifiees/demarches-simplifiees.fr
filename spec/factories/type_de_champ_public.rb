FactoryGirl.define do
  factory :type_de_champ_public do
    libelle 'Description'
    description 'description de votre projet'
    type_champ 'text'
    order_place 1
    mandatory false

    trait :checkbox do
      type_champ 'checkbox'
    end
  end
end
