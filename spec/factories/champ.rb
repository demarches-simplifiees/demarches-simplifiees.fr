FactoryBot.define do
  factory :champ do
    type_de_champ { FactoryBot.create(:type_de_champ) }

    trait :checkbox do
      type_de_champ { FactoryBot.create(:type_de_champ, :checkbox) }
    end

    trait :header_section do
      type_de_champ { FactoryBot.create(:type_de_champ, :header_section) }
    end

    trait :explication do
      type_de_champ { FactoryBot.create(:type_de_champ, :explication) }
    end

    trait :dossier_link do
      type_de_champ { FactoryBot.create(:type_de_champ, :type_dossier_link) }
    end
  end
end
