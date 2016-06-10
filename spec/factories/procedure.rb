FactoryGirl.define do
  factory :procedure do
    lien_demarche 'http://localhost'
    libelle 'Demande de subvention'
    description "Demande de subvention à l'intention des associations"
    organisation "Orga SGMAP"
    direction "direction SGMAP"
    published false

    after(:build) do |procedure, _evaluator|
      if procedure.module_api_carto.nil?
        module_api_carto = create(:module_api_carto)
        procedure.module_api_carto = module_api_carto
      end
    end

    trait :with_api_carto do
      after(:build) do |procedure, _evaluator|
        procedure.module_api_carto.use_api_carto = true
      end
    end

    trait :with_type_de_champ do
      after(:build) do |procedure, _evaluator|
        type_de_champ = create(:type_de_champ)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_type_de_champ_mandatory do
      after(:build) do |procedure, _evaluator|
        type_de_champ = create(:type_de_champ, mandatory: true)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_two_type_de_piece_justificative do
      after(:build) do |procedure, _evaluator|
        rib = create(:type_de_piece_justificative, :rib)
        msa = create(:type_de_piece_justificative, :msa)

        procedure.types_de_piece_justificative << rib
        procedure.types_de_piece_justificative << msa
      end
    end

    trait :published do
      after(:build) do |procedure, _evaluator|
        procedure.published = true
      end
    end
  end
end
