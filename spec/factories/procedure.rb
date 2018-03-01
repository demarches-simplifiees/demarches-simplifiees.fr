FactoryBot.define do
  sequence(:published_path) { |n| "fake_path#{n}" }
  factory :procedure do
    lien_demarche 'http://localhost'
    sequence(:libelle) { |n| "Procedure #{n}" }
    description "Demande de subvention à l'intention des associations"
    organisation "Orga DINSIC"
    direction "direction DINSIC"
    published_at nil
    cerfa_flag false
    administrateur { create(:administrateur) }

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

    trait :for_individual do
      after(:build) do |procedure, _evaluator|
        procedure.for_individual = true
      end
    end

    trait :with_type_de_champ do
      transient do
        types_de_champ_count 1
      end

      after(:build) do |procedure, evaluator|
        evaluator.types_de_champ_count.times do
          type_de_champ = create(:type_de_champ)

          procedure.types_de_champ << type_de_champ
        end
      end
    end

    trait :with_type_de_champ_private do
      transient do
        types_de_champ_private_count 1
      end

      after(:build) do |procedure, evaluator|
        evaluator.types_de_champ_private_count.times do
          type_de_champ = create(:type_de_champ, :private)

          procedure.types_de_champ_private << type_de_champ
        end
      end
    end

    trait :with_type_de_champ_mandatory do
      after(:build) do |procedure, _evaluator|
        type_de_champ = create(:type_de_champ, mandatory: true)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_datetime do
      after(:build) do |procedure, _evaluator|
        type_de_champ = create(:type_de_champ, mandatory: true, type_champ: :datetime)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_dossier_link do
      after(:build) do |procedure, _evaluator|
        type_de_champ = create(:type_de_champ, :type_dossier_link)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_yes_no do
      after(:build) do |procedure, _evaluator|
        type_de_champ = create(:type_de_champ, :type_yes_no)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_two_type_de_piece_justificative do
      after(:build) do |procedure, _evaluator|
        rib = create(:type_de_piece_justificative, :rib, order_place: 1)
        msa = create(:type_de_piece_justificative, :msa, order_place: 2)

        procedure.types_de_piece_justificative << rib
        procedure.types_de_piece_justificative << msa
      end
    end

    trait :published do
      after(:create) do |procedure, _evaluator|
        procedure.publish!(generate(:published_path))
      end
    end

    trait :archived do
      after(:build) do |procedure, _evaluator|
        procedure.archived_at = Time.now
      end
    end

    trait :with_all_champs_mandatory do
      after(:build) do |procedure, _evaluator|
        tdcs = []
        tdcs << create(:type_de_champ, type_champ: 'text', mandatory: true, libelle: 'text')
        tdcs << create(:type_de_champ, type_champ: 'textarea', mandatory: true, libelle: 'textarea')
        tdcs << create(:type_de_champ, type_champ: 'date', mandatory: true, libelle: 'date')
        tdcs << create(:type_de_champ, type_champ: 'datetime', mandatory: true, libelle: 'datetime')
        tdcs << create(:type_de_champ, type_champ: 'number', mandatory: true, libelle: 'number')
        tdcs << create(:type_de_champ, type_champ: 'checkbox', mandatory: true, libelle: 'checkbox')
        tdcs << create(:type_de_champ, type_champ: 'civilite', mandatory: true, libelle: 'civilite')
        tdcs << create(:type_de_champ, type_champ: 'email', mandatory: true, libelle: 'email')
        tdcs << create(:type_de_champ, type_champ: 'phone', mandatory: true, libelle: 'phone')
        tdcs << create(:type_de_champ, type_champ: 'yes_no', mandatory: true, libelle: 'yes_no')
        tdcs << create(:type_de_champ, :type_drop_down_list, mandatory: true, libelle: 'simple_drop_down_list')
        tdcs << create(:type_de_champ, :type_drop_down_list, type_champ: 'multiple_drop_down_list', mandatory: true, libelle: 'multiple_drop_down_list')
        tdcs << create(:type_de_champ, type_champ: 'pays', mandatory: true, libelle: 'pays')
        tdcs << create(:type_de_champ, type_champ: 'regions', mandatory: true, libelle: 'regions')
        tdcs << create(:type_de_champ, type_champ: 'departements', mandatory: true, libelle: 'departements')
        tdcs << create(:type_de_champ, type_champ: 'engagement', mandatory: true, libelle: 'engagement')
        tdcs << create(:type_de_champ, type_champ: 'header_section', mandatory: true, libelle: 'header_section')
        tdcs << create(:type_de_champ, type_champ: 'explication', mandatory: true, libelle: 'explication')
        tdcs << create(:type_de_champ, :type_dossier_link, mandatory: true, libelle: 'dossier_link')
        tdcs << create(:type_de_champ, type_champ: 'piece_justificative', mandatory: true, libelle: 'piece_justificative')

        procedure.types_de_champ = tdcs
      end
    end
  end
end
