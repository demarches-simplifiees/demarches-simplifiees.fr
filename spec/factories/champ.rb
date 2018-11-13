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

  factory :champ_integer_number, class: 'Champs::IntegerNumberChamp' do
    type_de_champ { create(:type_de_champ_integer_number) }
    value { '42' }
  end

  factory :champ_decimal_number, class: 'Champs::DecimalNumberChamp' do
    type_de_champ { create(:type_de_champ_decimal_number) }
    value { '42.1' }
  end

  factory :champ_linked_drop_down_list, class: 'Champs::LinkedDropDownListChamp' do
    type_de_champ { create(:type_de_champ_linked_drop_down_list) }
    value { '{}' }
  end

  factory :champ_carte, class: 'Champs::CarteChamp' do
    type_de_champ { create(:type_de_champ_carte) }
  end

  factory :champ_siret, class: 'Champs::SiretChamp' do
    type_de_champ { create(:type_de_champ_siret) }
    value { '44011762001530' }
    etablissement { create(:etablissement) }

    before(:create) do |champ, evaluator|
      champ.etablissement.signature = champ.etablissement.sign
    end
  end

  factory :champ_piece_justificative, class: 'Champs::PieceJustificativeChamp' do
    type_de_champ { create(:type_de_champ_piece_justificative) }

    after(:create) do |champ, evaluator|
      champ.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
    end
  end
end
