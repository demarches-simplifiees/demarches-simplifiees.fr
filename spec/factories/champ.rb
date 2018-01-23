FactoryBot.define do
  factory :champ do
    type_de_champ { FactoryBot.create(:type_de_champ_public) }

    trait :checkbox do
      type_de_champ { FactoryBot.create(:type_de_champ_public, :checkbox) }
    end

    trait :header_section do
      type_de_champ { FactoryBot.create(:type_de_champ_public, :header_section) }
    end

    trait :explication do
      type_de_champ { FactoryBot.create(:type_de_champ_public, :explication) }
    end

    trait :dossier_link do
      type_de_champ { FactoryBot.create(:type_de_champ_public, :type_dossier_link) }
    end
  end
end
