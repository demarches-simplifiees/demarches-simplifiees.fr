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

    trait :piece_justificative do
      type_de_champ { create(:type_de_champ_piece_justificative) }
    end

    trait :with_piece_justificative_file do
      after(:create) do |champ, evaluator|
        champ.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
      end
    end
  end
end
