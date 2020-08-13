FactoryBot.define do
  factory :type_de_champ do
    sequence(:libelle) { |n| "Libelle du champ #{n}" }
    sequence(:description) { |n| "description du champ #{n}" }
    type_champ { TypeDeChamp.type_champs.fetch(:text) }
    order_place { 1 }
    mandatory { false }
    add_attribute(:private) { false }

    factory :type_de_champ_text do
      type_champ { TypeDeChamp.type_champs.fetch(:text) }
    end
    factory :type_de_champ_textarea do
      type_champ { TypeDeChamp.type_champs.fetch(:textarea) }
    end
    factory :type_de_champ_number do
      type_champ { TypeDeChamp.type_champs.fetch(:number) }
    end
    factory :type_de_champ_decimal_number do
      type_champ { TypeDeChamp.type_champs.fetch(:decimal_number) }
    end
    factory :type_de_champ_integer_number do
      type_champ { TypeDeChamp.type_champs.fetch(:integer_number) }
    end
    factory :type_de_champ_checkbox do
      type_champ { TypeDeChamp.type_champs.fetch(:checkbox) }
    end
    factory :type_de_champ_civilite do
      type_champ { TypeDeChamp.type_champs.fetch(:civilite) }
    end
    factory :type_de_champ_email do
      type_champ { TypeDeChamp.type_champs.fetch(:email) }
    end
    factory :type_de_champ_phone do
      type_champ { TypeDeChamp.type_champs.fetch(:phone) }
    end
    factory :type_de_champ_address do
      type_champ { TypeDeChamp.type_champs.fetch(:address) }
    end
    factory :type_de_champ_yes_no do
      libelle { 'Yes/no' }
      type_champ { TypeDeChamp.type_champs.fetch(:yes_no) }
    end
    factory :type_de_champ_date do
      type_champ { TypeDeChamp.type_champs.fetch(:date) }
    end
    factory :type_de_champ_datetime do
      type_champ { TypeDeChamp.type_champs.fetch(:datetime) }
    end
    factory :type_de_champ_drop_down_list do
      libelle { 'Choix parmi une liste' }
      type_champ { TypeDeChamp.type_champs.fetch(:drop_down_list) }
      drop_down_list_value { "val1\r\nval2\r\n--separateur--\r\nval3" }
      trait :long do
        drop_down_list_value { "alpha\r\nbravo\r\n--separateur--\r\ncharly\r\ndelta\r\necho\r\nfox-trot\r\ngolf" }
      end
    end
    factory :type_de_champ_multiple_drop_down_list do
      type_champ { TypeDeChamp.type_champs.fetch(:multiple_drop_down_list) }
      drop_down_list_value { "val1\r\nval2\r\n--separateur--\r\nval3" }
      trait :long do
        drop_down_list_value { "alpha\r\nbravo\r\n--separateur--\r\ncharly\r\ndelta\r\necho\r\nfox-trot\r\ngolf" }
      end
    end
    factory :type_de_champ_linked_drop_down_list do
      type_champ { TypeDeChamp.type_champs.fetch(:linked_drop_down_list) }
      drop_down_list_value { "--primary--\nsecondary\n" }
    end
    factory :type_de_champ_pays do
      type_champ { TypeDeChamp.type_champs.fetch(:pays) }
    end
    factory :type_de_champ_regions do
      type_champ { TypeDeChamp.type_champs.fetch(:regions) }
    end
    factory :type_de_champ_departements do
      type_champ { TypeDeChamp.type_champs.fetch(:departements) }
    end
    factory :type_de_champ_communes do
      type_champ { TypeDeChamp.type_champs.fetch(:communes) }
    end
    factory :type_de_champ_engagement do
      type_champ { TypeDeChamp.type_champs.fetch(:engagement) }
    end
    factory :type_de_champ_header_section do
      type_champ { TypeDeChamp.type_champs.fetch(:header_section) }
    end
    factory :type_de_champ_explication do
      type_champ { TypeDeChamp.type_champs.fetch(:explication) }
    end
    factory :type_de_champ_dossier_link do
      libelle { 'Référence autre dossier' }
      type_champ { TypeDeChamp.type_champs.fetch(:dossier_link) }
    end
    factory :type_de_champ_piece_justificative do
      type_champ { TypeDeChamp.type_champs.fetch(:piece_justificative) }

      after(:create) do |tc, _evaluator|
        tc.piece_justificative_template.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
      end
    end
    factory :type_de_champ_siret do
      type_champ { TypeDeChamp.type_champs.fetch(:siret) }
    end
    factory :type_de_champ_carte do
      type_champ { TypeDeChamp.type_champs.fetch(:carte) }
    end
    factory :type_de_champ_repetition do
      type_champ { TypeDeChamp.type_champs.fetch(:repetition) }

      trait :with_types_de_champ do
        after(:build) do |type_de_champ, _evaluator|
          type_de_champ.types_de_champ << create(:type_de_champ, libelle: 'sub type de champ')
        end
      end
    end

    trait :private do
      add_attribute(:private) { true }
      sequence(:libelle) { |n| "Libelle champ privé #{n}" }
      sequence(:description) { |n| "description du champ privé #{n}" }
    end
  end
end
