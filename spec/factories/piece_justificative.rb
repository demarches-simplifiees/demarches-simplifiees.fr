FactoryGirl.define do
  factory :piece_justificative do
    trait :rib do
      content '/chemin/vers/RIB'
    end

    trait :contrat do
      content '/chemin/vers/Contrat'
    end
  end
end
