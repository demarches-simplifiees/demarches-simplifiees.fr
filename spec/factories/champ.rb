FactoryGirl.define do
  factory :champ do
    type_de_champ { FactoryGirl.create(:type_de_champ_public) }
  end
end
