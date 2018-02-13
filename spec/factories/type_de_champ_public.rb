FactoryBot.define do
  factory :type_de_champ_public, class: 'TypeDeChamp' do
    private false
    sequence(:libelle) { |n| "Libelle du champ #{n}" }
    sequence(:description) { |n| "description du champ #{n}" }
    type_champ 'text'
    order_place 1
    mandatory false

    trait :checkbox do
      type_champ 'checkbox'
    end

    trait :header_section do
      type_champ 'header_section'
    end

    trait :explication do
      type_champ 'explication'
    end

    trait :type_dossier_link do
      libelle 'Référence autre dossier'
      type_champ 'dossier_link'
    end

    trait :type_yes_no do
      libelle 'Yes/no'
      type_champ 'yes_no'
    end

    trait :type_drop_down_list do
      libelle 'Menu déroulant'
      type_champ 'drop_down_list'
      drop_down_list { create(:drop_down_list) }
    end
  end
end
