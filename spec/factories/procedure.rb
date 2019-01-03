FactoryBot.define do
  sequence(:published_path) { |n| "fake_path#{n}" }
  factory :procedure do
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

      after(:build) do |procedure, evaluator|
        procedure.dossiers << create_list(:dossier, evaluator.dossiers_count, procedure: procedure)
      end
    end

    factory :simple_procedure do
      after(:build) do |procedure, _evaluator|
        procedure.for_individual = true
        procedure.types_de_champ << create(:type_de_champ, libelle: 'Texte obligatoire', mandatory: true)
        procedure.publish!(generate(:published_path))
      end
    end

    trait :with_path do
      path { generate(:published_path) }
    end

    trait :with_service do
      after(:build) do |procedure, _evaluator|
        procedure.service = create(:service)
      end
    end

    trait :with_gestionnaire do
      after(:build) do |procedure, _evaluator|
        procedure.gestionnaires << create(:gestionnaire)
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

    trait :archived_automatically do
      # For now the behavior is the same than :archived
      # (it may be different in the future though)
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
        procedure.update(whitelisted_at: Time.zone.now)
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
        procedure.types_de_champ = TypeDeChamp.type_champs.map.with_index do |(libelle, type_champ), index|
          if libelle == 'drop_down_list'
            libelle = 'simple_drop_down_list'
          end
          build(:"type_de_champ_#{type_champ}", mandatory: true, libelle: libelle, order_place: index)
        end
      end
    end

    trait :with_all_champs do
      after(:build) do |procedure, _evaluator|
        procedure.types_de_champ = TypeDeChamp.type_champs.map.with_index do |(libelle, type_champ), index|
          if libelle == 'drop_down_list'
            libelle = 'simple_drop_down_list'
          end
          build(:"type_de_champ_#{type_champ}", libelle: libelle, order_place: index)
        end
      end
    end

    trait :with_all_annotations do
      after(:build) do |procedure, _evaluator|
        procedure.types_de_champ_private = TypeDeChamp.type_champs.map.with_index do |(libelle, type_champ), index|
          if libelle == 'drop_down_list'
            libelle = 'simple_drop_down_list'
          end
          build(:"type_de_champ_#{type_champ}", private: true, libelle: libelle, order_place: index)
        end
      end
    end
  end
end
