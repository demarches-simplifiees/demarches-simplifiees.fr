FactoryBot.define do
  factory :champ do
    type_de_champ { create(:type_de_champ) }

    trait :checkbox do
      type_de_champ { create(:type_de_champ_checkbox) }
    end

    trait :header_section do
      type_de_champ { create(:type_de_champ_header_section) }
    end

    trait :explication do
      type_de_champ { create(:type_de_champ_explication) }
    end

    trait :dossier_link do
      type_de_champ { create(:type_de_champ_dossier_link) }
    end
  end
end
