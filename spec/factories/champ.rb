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
      after(:create) do |champ, _evaluator|
        champ.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
      end
    end
  end

  factory :champ_text, class: 'Champs::TextChamp' do
    type_de_champ { create(:type_de_champ_text) }
    value { 'text' }
  end

  factory :champ_textarea, class: 'Champs::TextareaChamp' do
    type_de_champ { create(:type_de_champ_textarea) }
    value { 'textarea' }
  end

  factory :champ_date, class: 'Champs::DateChamp' do
    type_de_champ { create(:type_de_champ_date) }
    value { '2019-07-10' }
  end

  factory :champ_datetime, class: 'Champs::DatetimeChamp' do
    type_de_champ { create(:type_de_champ_datetime) }
    value { '15/09/1962 15:35' }
  end

  factory :champ_number, class: 'Champs::NumberChamp' do
    type_de_champ { create(:type_de_champ_number) }
    value { '42' }
  end

  factory :champ_decimal_number, class: 'Champs::DecimalNumberChamp' do
    type_de_champ { create(:type_de_champ_decimal_number) }
    value { '42.1' }
  end

  factory :champ_integer_number, class: 'Champs::IntegerNumberChamp' do
    type_de_champ { create(:type_de_champ_integer_number) }
    value { '42' }
  end

  factory :champ_checkbox, class: 'Champs::CheckboxChamp' do
    type_de_champ { create(:type_de_champ_checkbox) }
    value { 'on' }
  end

  factory :champ_civilite, class: 'Champs::CiviliteChamp' do
    type_de_champ { create(:type_de_champ_civilite) }
    value { 'M.' }
  end

  factory :champ_email, class: 'Champs::EmailChamp' do
    type_de_champ { create(:type_de_champ_email) }
    value { 'yoda@beta.gouv.fr' }
  end

  factory :champ_phone, class: 'Champs::PhoneChamp' do
    type_de_champ { create(:type_de_champ_phone) }
    value { '0666666666' }
  end

  factory :champ_address, class: 'Champs::AddressChamp' do
    type_de_champ { create(:type_de_champ_address) }
    value { '2 rue des Démarches' }
  end

  factory :champ_yes_no, class: 'Champs::YesNoChamp' do
    type_de_champ { create(:type_de_champ_yes_no) }
    value { 'true' }
  end

  factory :champ_drop_down_list, class: 'Champs::DropDownListChamp' do
    type_de_champ { create(:type_de_champ_drop_down_list) }
    value { 'choix 1' }
  end

  factory :champ_multiple_drop_down_list, class: 'Champs::MultipleDropDownListChamp' do
    type_de_champ { create(:type_de_champ_multiple_drop_down_list) }
    value { '["choix 1", "choix 2"]' }
  end

  factory :champ_linked_drop_down_list, class: 'Champs::LinkedDropDownListChamp' do
    type_de_champ { create(:type_de_champ_linked_drop_down_list) }
    value { '["categorie 1", "choix 1"]' }
  end

  factory :champ_pays, class: 'Champs::PaysChamp' do
    type_de_champ { create(:type_de_champ_pays) }
    value { 'France' }
  end

  factory :champ_regions, class: 'Champs::RegionChamp' do
    type_de_champ { create(:type_de_champ_regions) }
    value { 'Guadeloupe' }
  end

  factory :champ_departements, class: 'Champs::DepartementChamp' do
    type_de_champ { create(:type_de_champ_departements) }
    value { '971 - Guadeloupe' }
  end

  factory :champ_engagement, class: 'Champs::EngagementChamp' do
    type_de_champ { create(:type_de_champ_engagement) }
    value { 'true' }
  end

  factory :champ_header_section, class: 'Champs::HeaderSectionChamp' do
    type_de_champ { create(:type_de_champ_header_section) }
    value { 'une section' }
  end

  factory :champ_explication, class: 'Champs::ExplicationChamp' do
    type_de_champ { create(:type_de_champ_explication) }
    value { '' }
  end

  factory :champ_dossier_link, class: 'Champs::DossierLinkChamp' do
    type_de_champ { create(:type_de_champ_dossier_link) }
    value { create(:dossier).id }
  end

  factory :champ_piece_justificative, class: 'Champs::PieceJustificativeChamp' do
    type_de_champ { create(:type_de_champ_piece_justificative) }

    after(:build) do |champ, _evaluator|
      champ.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
    end
  end

  factory :champ_carte, class: 'Champs::CarteChamp' do
    type_de_champ { create(:type_de_champ_carte) }
  end

  factory :champ_siret, class: 'Champs::SiretChamp' do
    association :type_de_champ, factory: [:type_de_champ_siret]
    association :etablissement, factory: [:etablissement]
    value { '44011762001530' }
  end

  factory :champ_repetition, class: 'Champs::RepetitionChamp' do
    type_de_champ { create(:type_de_champ_repetition) }

    after(:build) do |champ_repetition, _evaluator|
      type_de_champ_text = create(:type_de_champ_text, order_place: 0, parent: champ_repetition.type_de_champ, libelle: 'Nom')
      type_de_champ_number = create(:type_de_champ_number, order_place: 1, parent: champ_repetition.type_de_champ, libelle: 'Age')

      create(:champ_text, row: 0, type_de_champ: type_de_champ_text, parent: champ_repetition)
      create(:champ_number, row: 0, type_de_champ: type_de_champ_number, parent: champ_repetition)
      create(:champ_text, row: 1, type_de_champ: type_de_champ_text, parent: champ_repetition)
      create(:champ_number, row: 1, type_de_champ: type_de_champ_number, parent: champ_repetition)
    end
  end
end
