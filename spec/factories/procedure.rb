FactoryBot.define do
  sequence(:published_path) { |n| "fake_path#{n}" }
  factory :procedure do
    sequence(:libelle) { |n| "Procedure #{n}" }
    description { "Demande de subvention à l'intention des associations" }
    organisation { "Orga DINUM" }
    direction { "direction DINUM" }
    cadre_juridique { "un cadre juridique important" }
    published_at { nil }
    duree_conservation_dossiers_dans_ds { 3 }
    duree_conservation_dossiers_hors_ds { 6 }
    ask_birthday { false }
    lien_site_web { "https://mon-site.gouv" }
    path { SecureRandom.uuid }

    transient do
      administrateur { }
      instructeurs { [] }
    end

    after(:build) do |procedure, evaluator|
      if evaluator.administrateur
        procedure.administrateurs = [evaluator.administrateur]
      elsif procedure.administrateurs.empty?
        procedure.administrateurs = [create(:administrateur)]
      end
    end

    after(:create) do |procedure, evaluator|
      evaluator.instructeurs.each { |i| i.assign_to_procedure(procedure) }
    end

    factory :procedure_with_dossiers do
      transient do
        dossiers_count { 1 }
      end

      after(:create) do |procedure, evaluator|
        user = create(:user)
        evaluator.dossiers_count.times do
          dossier = procedure.new_dossier
          dossier.user = user
          dossier.save!
        end
      end
    end

    factory :simple_procedure do
      after(:build) do |procedure, _evaluator|
        procedure.for_individual = true
        procedure.types_de_champ << build(:type_de_champ, libelle: 'Texte obligatoire', mandatory: true)
        procedure.path = generate(:published_path)
        procedure.publish!
      end
    end

    trait :with_logo do
      logo { Rack::Test::UploadedFile.new('spec/fixtures/files/logo_test_procedure.png', 'image/png') }
    end

    trait :with_path do
      path { generate(:published_path) }
    end

    trait :with_service do
      after(:build) do |procedure, _evaluator|
        procedure.service = create(:service)
      end
    end

    trait :with_instructeur do
      after(:create) do |procedure, _evaluator|
        procedure.defaut_groupe_instructeur.instructeurs << build(:instructeur)
      end
    end

    trait :routee do
      after(:create) do |procedure, _evaluator|
        procedure.groupe_instructeurs.create(label: '2nd groupe')
      end
    end

    trait :for_individual do
      after(:build) do |procedure, _evaluator|
        procedure.for_individual = true
      end
    end

    trait :with_auto_archive do
      auto_archive_on { Time.zone.today + 20 }
    end

    trait :with_type_de_champ do
      transient do
        types_de_champ_count { 1 }
      end

      after(:build) do |procedure, evaluator|
        evaluator.types_de_champ_count.times do
          type_de_champ = build(:type_de_champ)

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
          type_de_champ = build(:type_de_champ, :private)

          procedure.types_de_champ_private << type_de_champ
        end
      end
    end

    trait :with_type_de_champ_mandatory do
      after(:build) do |procedure, _evaluator|
        type_de_champ = build(:type_de_champ, mandatory: true)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_datetime do
      after(:build) do |procedure, _evaluator|
        type_de_champ = build(:type_de_champ_datetime, mandatory: true)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_dossier_link do
      after(:build) do |procedure, _evaluator|
        type_de_champ = build(:type_de_champ_dossier_link)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_yes_no do
      after(:build) do |procedure, _evaluator|
        type_de_champ = build(:type_de_champ_yes_no)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_piece_justificative do
      after(:build) do |procedure, _evaluator|
        type_de_champ = build(:type_de_champ_piece_justificative)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :with_repetition do
      after(:build) do |procedure, _evaluator|
        type_de_champ = build(:type_de_champ_repetition)
        procedure.types_de_champ << type_de_champ

        type_de_champ.types_de_champ << build(:type_de_champ, libelle: 'sub type de champ')
      end
    end

    trait :with_number do
      after(:build) do |procedure, _evaluator|
        type_de_champ = build(:type_de_champ_number)

        procedure.types_de_champ << type_de_champ
      end
    end

    trait :published do
      after(:build) do |procedure, _evaluator|
        procedure.path = generate(:published_path)
        procedure.publish!
      end
    end

    trait :closed do
      after(:build) do |procedure, _evaluator|
        procedure.path = generate(:published_path)
        procedure.publish!
        procedure.close!
      end
    end

    trait :unpublished do
      after(:build) do |procedure, _evaluator|
        procedure.path = generate(:published_path)
        procedure.publish!
        procedure.unpublish!
      end
    end

    trait :discarded do
      hidden_at { Time.zone.now }
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
        procedure.types_de_champ << build(:type_de_champ_drop_down_list, :long, mandatory: true, libelle: 'simple_choice_drop_down_list_long')
        procedure.types_de_champ << build(:type_de_champ_multiple_drop_down_list, :long, mandatory: true, libelle: 'multiple_choice_drop_down_list_long')
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
