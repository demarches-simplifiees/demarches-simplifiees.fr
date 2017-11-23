FactoryGirl.define do
  factory :type_de_champ_private do
    sequence(:libelle) { |n| "Libelle champ privé #{n}" }
    sequence(:description) { |n| "description du champ privé #{n}" }
    type_champ 'text'
    order_place 1
    mandatory false

    trait :drop_down_list do
      libelle 'Menu déroulant'
      type_champ 'drop_down_list'
      drop_down_list { create(:drop_down_list) }
    end
  end
end
