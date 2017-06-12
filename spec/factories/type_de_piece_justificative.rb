FactoryGirl.define do
  factory :type_de_piece_justificative do
    libelle 'RIB'
    description 'Releve identité bancaire'

    trait :rib do
      libelle 'RIB'
      description 'Releve identité bancaire'
      api_entreprise false
    end

    trait :msa do
      libelle 'Attestation MSA'
      description 'recuperation automatique'
      api_entreprise true
    end
  end
end
