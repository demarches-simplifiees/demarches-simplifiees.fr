FactoryBot.define do
  sequence(:published_path) { |n| "fake_path#{n}" }
  factory :procedure do
    lien_demarche { 'http://localhost' }
    sequence(:libelle) { |n| "Procedure #{n}" }
    description { "Demande de subvention à l'intention des associations" }
    organisation { "Orga DINSIC" }
    direction { "direction DINSIC" }
    cadre_juridique { "un cadre juridique important" }
    published_at { nil }
    administrateur { create(:administrateur) }
    duree_conservation_dossiers_dans_ds { 3 }
    duree_conservation_dossiers_hors_ds { 6 }

    factory :procedure_with_dossiers do
      transient do
        dossiers_count { 1 }
      end

      after(:build) do |procedure, _evaluator|
        procedure.dossiers << create_list(:dossier, _evaluator.dossiers_count, procedure: procedure)
      end
    end

    factory :simple_procedure do
      after(:build) do |procedure, _evaluator|
        procedure.for_individual = true
        procedure.types_de_champ << create(:type_de_champ, libelle: 'Texte obligatoire', mandatory: true)
        procedure.publish!(generate(:published_path))
      end
    end

    after(:build) do |procedure, _evaluator|
      if procedure.module_api_carto.nil?
        module_api_carto = create(:module_api_carto)
        procedure.module_api_carto = module_api_carto
      end
    end

    trait :with_path do
      after(:create) do |procedure|
        create(:procedure_path,
          procedure: procedure,
          administrateur: procedure.administrateur,
          path: generate(:published_path))
      end
    end

    trait :with_service do
      after(:build) do |procedure, _evaluator|
        procedure.service = create(:service)
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
        types_de_champ_count { 1 }
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
        types_de_champ_private_count { 1 }
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
        type_de_champ = create(:type_de_champ_datetime, mandatory: true)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_dossier_link do
      after(:build) do |procedure, _evaluator|
        type_de_champ = create(:type_de_champ_dossier_link)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_yes_no do
      after(:build) do |procedure, _evaluator|
        type_de_champ = create(:type_de_champ_yes_no)

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
      after(:build) do |procedure, _evaluator|
        procedure.publish!(generate(:published_path))
      end
    end

    trait :archived do
      after(:build) do |procedure, _evaluator|
        procedure.publish!(generate(:published_path))
        procedure.archive!
      end
    end

    trait :hidden do
      after(:build) do |procedure, _evaluator|
        procedure.publish!(generate(:published_path))
        procedure.hide!
      end
    end

    trait :whitelisted do
      after(:build) do |procedure, _evaluator|
        procedure.update(whitelisted_at: DateTime.now)
      end
    end

    trait :with_notice do
      after(:create) do |procedure, _evaluator|
        procedure.notice.attach(
          io: StringIO.new('Hello World'),
          filename: 'hello.txt'
        )
      end
    end

    trait :with_deliberation do
      after(:create) do |procedure, _evaluator|
        procedure.deliberation.attach(
          io: StringIO.new('Hello World'),
          filename: 'hello.txt'
        )
      end
    end

    trait :with_all_champs_mandatory do
      after(:build) do |procedure, _evaluator|
        tdcs = []
        tdcs << create(:type_de_champ, mandatory: true, libelle: 'text')
        tdcs << create(:type_de_champ_textarea, mandatory: true, libelle: 'textarea')
        tdcs << create(:type_de_champ_date, mandatory: true, libelle: 'date')
        tdcs << create(:type_de_champ_datetime, mandatory: true, libelle: 'datetime')
        tdcs << create(:type_de_champ_number, mandatory: true, libelle: 'number')
        tdcs << create(:type_de_champ_checkbox, mandatory: true, libelle: 'checkbox')
        tdcs << create(:type_de_champ_civilite, mandatory: true, libelle: 'civilite')
        tdcs << create(:type_de_champ_email, mandatory: true, libelle: 'email')
        tdcs << create(:type_de_champ_phone, mandatory: true, libelle: 'phone')
        tdcs << create(:type_de_champ_yes_no, mandatory: true, libelle: 'yes_no')
        tdcs << create(:type_de_champ_drop_down_list, mandatory: true, libelle: 'simple_drop_down_list')
        tdcs << create(:type_de_champ_multiple_drop_down_list, mandatory: true, libelle: 'multiple_drop_down_list')
        tdcs << create(:type_de_champ_pays, mandatory: true, libelle: 'pays')
        tdcs << create(:type_de_champ_regions, mandatory: true, libelle: 'regions')
        tdcs << create(:type_de_champ_departements, mandatory: true, libelle: 'departements')
        tdcs << create(:type_de_champ_engagement, mandatory: true, libelle: 'engagement')
        tdcs << create(:type_de_champ_header_section, mandatory: true, libelle: 'header_section')
        tdcs << create(:type_de_champ_explication, mandatory: true, libelle: 'explication')
        tdcs << create(:type_de_champ_dossier_link, mandatory: true, libelle: 'dossier_link')
        tdcs << create(:type_de_champ_piece_justificative, mandatory: true, libelle: 'piece_justificative')
        procedure.types_de_champ = tdcs
      end
    end
  end
end
