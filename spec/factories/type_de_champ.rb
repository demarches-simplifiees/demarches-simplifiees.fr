FactoryBot.define do
  factory :type_de_champ, class: 'TypesDeChamp::TextTypeDeChamp' do
    private false
    sequence(:libelle) { |n| "Libelle du champ #{n}" }
    sequence(:description) { |n| "description du champ #{n}" }
    type_champ 'text'
    order_place 1
    mandatory false

    factory :type_de_champ_text, class: 'TypesDeChamp::TextTypeDeChamp' do
      type_champ 'text'
    end
    factory :type_de_champ_textarea, class: 'TypesDeChamp::TextareaTypeDeChamp' do
      type_champ 'textarea'
    end
    factory :type_de_champ_number, class: 'TypesDeChamp::NumberTypeDeChamp' do
      type_champ 'number'
    end
    factory :type_de_champ_checkbox, class: 'TypesDeChamp::CheckboxTypeDeChamp' do
      type_champ 'checkbox'
    end
    factory :type_de_champ_civilite, class: 'TypesDeChamp::CiviliteTypeDeChamp' do
      type_champ 'civilite'
    end
    factory :type_de_champ_email, class: 'TypesDeChamp::EmailTypeDeChamp' do
      type_champ 'email'
    end
    factory :type_de_champ_phone, class: 'TypesDeChamp::PhoneTypeDeChamp' do
      type_champ 'phone'
    end
    factory :type_de_champ_address, class: 'TypesDeChamp::AddressTypeDeChamp' do
      type_champ 'address'
    end
    factory :type_de_champ_yes_no, class: 'TypesDeChamp::YesNoTypeDeChamp' do
      libelle 'Yes/no'
      type_champ 'yes_no'
    end
    factory :type_de_champ_date, class: 'TypesDeChamp::DateTypeDeChamp' do
      type_champ 'date'
    end
    factory :type_de_champ_datetime, class: 'TypesDeChamp::DatetimeTypeDeChamp' do
      type_champ 'datetime'
    end
    factory :type_de_champ_drop_down_list, class: 'TypesDeChamp::DropDownListTypeDeChamp' do
      libelle 'Menu déroulant'
      type_champ 'drop_down_list'
      drop_down_list { create(:drop_down_list) }
    end
    factory :type_de_champ_multiple_drop_down_list, class: 'TypesDeChamp::MultipleDropDownListTypeDeChamp' do
      type_champ 'multiple_drop_down_list'
      drop_down_list { create(:drop_down_list) }
    end
    factory :type_de_champ_pays, class: 'TypesDeChamp::PaysTypeDeChamp' do
      type_champ 'pays'
    end
    factory :type_de_champ_regions, class: 'TypesDeChamp::RegionTypeDeChamp' do
      type_champ 'regions'
    end
    factory :type_de_champ_departements, class: 'TypesDeChamp::DepartementTypeDeChamp' do
      type_champ 'departements'
    end
    factory :type_de_champ_engagement, class: 'TypesDeChamp::EngagementTypeDeChamp' do
      type_champ 'engagement'
    end
    factory :type_de_champ_header_section, class: 'TypesDeChamp::HeaderSectionTypeDeChamp' do
      type_champ 'header_section'
    end
    factory :type_de_champ_explication, class: 'TypesDeChamp::ExplicationTypeDeChamp' do
      type_champ 'explication'
    end
    factory :type_de_champ_dossier_link, class: 'TypesDeChamp::DossierLinkTypeDeChamp' do
      libelle 'Référence autre dossier'
      type_champ 'dossier_link'
    end
    factory :type_de_champ_piece_justificative, class: 'TypesDeChamp::PieceJustificativeTypeDeChamp' do
      type_champ 'piece_justificative'
    end
    factory :type_de_champ_siret, class: 'TypesDeChamp::SiretTypeDeChamp' do
      type_champ 'siret'
    end

    trait :private do
      private true
      sequence(:libelle) { |n| "Libelle champ privé #{n}" }
      sequence(:description) { |n| "description du champ privé #{n}" }
    end
  end
end
