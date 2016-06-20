FactoryGirl.define do
  factory :rna_information do
    association_id "W072000535"
    titre "ASSOCIATION POUR LA PROMOTION DE SPECTACLES AU CHATEAU DE ROCHEMAURE"
    objet "mise en oeuvre et réalisation de spectacles au chateau de rochemaure"
    date_creation "1990-04-24"
    date_declaration "2014-11-28"
    date_publication "1990-05-16"
    association :entreprise, factory: [:entreprise]
  end
end
