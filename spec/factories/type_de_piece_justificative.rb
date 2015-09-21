FactoryGirl.define do
  factory :type_de_piece_justificative do
    trait :rib do
      libelle 'RIB'
    end

    trait :contrat do
      libelle 'Contrat'
    end
  end
end
