FactoryGirl.define do
  factory :procedure do
    lien_demarche 'http://localhost'

    trait :with_two_type_de_piece_justificative do
      after(:build) do |procedure, _evaluator|
        rib = create(:type_de_piece_justificative, :rib)
        contrat = create(:type_de_piece_justificative, :contrat)

        procedure.types_de_piece_justificative << rib
        procedure.types_de_piece_justificative << contrat
      end
    end
  end
end
