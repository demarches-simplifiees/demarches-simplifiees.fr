FactoryGirl.define do
  factory :type_de_champ_public do
    sequence(:libelle) { |n| "Libelle du champ #{n}" }
    sequence(:description) { |n| "description du champ #{n}" }
    type_champ 'text'
    order_place 1
    mandatory false

    [
      :text,
      :textarea,
      :checkbox,
      :date,
      :datetime,
      :number,
      :civilite,
      :email,
      :header_section,
      :explication,
      :phone,
      :address,
      :pays,
      :regions,
      :departements,
      :engagement,
      :header_section,
      :explication,
      :dossier_link,
      :yes_no,
      :drop_down_list,
      :multiple_drop_down_list
    ].each do |type|
      trait type do
        libelle type.to_s.humanize
        type_champ type.to_s

        if type.in? [:drop_down_list, :multiple_drop_down_list]
          drop_down_list { create(:drop_down_list) }
        end
      end
    end
  end
end
