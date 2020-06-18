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
      procedure.draft_revision = build(:procedure_revision, procedure: procedure)
    end

    after(:create) do |procedure, evaluator|
      evaluator.instructeurs.each { |i| i.assign_to_procedure(procedure) }
      procedure.draft_revision.save
      procedure.reload
    end

    factory :procedure_with_dossiers do
      transient do
        dossiers_count { 1 }
      end

      after(:create) do |procedure, evaluator|
        user = create(:user)
        evaluator.dossiers_count.times do
          create(:dossier, procedure: procedure, user: user)
          # dossier = procedure.new_dossier
          # dossier.user = user
          # dossier.save!
        end
      end
    end

    factory :simple_procedure do
      after(:build) do |procedure, _evaluator|
        procedure.for_individual = true
        procedure.path = generate(:published_path)
        procedure.publish!
      end

      after(:create) do |procedure, _evaluator|
        create(:type_de_champ, procedure: procedure, libelle: 'Texte obligatoire', mandatory: true)
      end
    end

    trait :with_logo do
      logo { Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png') }
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
        procedure.defaut_groupe_instructeur.instructeurs << create(:instructeur)
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

      after(:create) do |procedure, evaluator|
        evaluator.types_de_champ_count.times do
          create(:type_de_champ, procedure: procedure)
        end
      end
    end

    trait :with_type_de_champ_private do
      transient do
        types_de_champ_private_count { 1 }
      end

      after(:create) do |procedure, evaluator|
        evaluator.types_de_champ_private_count.times do
          create(:type_de_champ, :private, procedure: procedure)
        end
      end
    end

    trait :with_type_de_champ_mandatory do
      after(:create) do |procedure, _evaluator|
        create(:type_de_champ, mandatory: true, procedure: procedure)
      end
    end

    trait :with_datetime do
      after(:create) do |procedure, _evaluator|
        create(:type_de_champ_datetime, mandatory: true, procedure: procedure)
      end
    end

    trait :with_dossier_link do
      after(:create) do |procedure, _evaluator|
        create(:type_de_champ_dossier_link, procedure: procedure)
      end
    end

    trait :with_yes_no do
      after(:create) do |procedure, _evaluator|
        create(:type_de_champ_yes_no, procedure: procedure)
      end
    end

    trait :with_piece_justificative do
      after(:create) do |procedure, _evaluator|
        create(:type_de_champ_piece_justificative, procedure: procedure)
      end
    end

    trait :with_repetition do
      after(:create) do |procedure, _evaluator|
        type_de_champ = create(:type_de_champ_repetition, procedure: procedure)
        create(:type_de_champ, libelle: 'sub type de champ', parent: type_de_champ)
      end
    end

    trait :with_number do
      after(:create) do |procedure, _evaluator|
        create(:type_de_champ_number, procedure: procedure)
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
      after(:create) do |procedure, _evaluator|
        TypeDeChamp.type_champs.map.with_index do |(libelle, type_champ), index|
          if libelle == 'drop_down_list'
            libelle = 'simple_drop_down_list'
          end
          create(:"type_de_champ_#{type_champ}", mandatory: true, libelle: libelle, position: index, procedure: procedure)
        end
        procedure.reload
      end
    end

    trait :with_all_champs do
      after(:create) do |procedure, _evaluator|
        TypeDeChamp.type_champs.map.with_index do |(libelle, type_champ), index|
          if libelle == 'drop_down_list'
            libelle = 'simple_drop_down_list'
          end
          create(:"type_de_champ_#{type_champ}", libelle: libelle, position: index, procedure: procedure)
        end
        procedure.reload
      end
    end

    trait :with_all_annotations do
      after(:create) do |procedure, _evaluator|
        TypeDeChamp.type_champs.map.with_index do |(libelle, type_champ), index|
          if libelle == 'drop_down_list'
            libelle = 'simple_drop_down_list'
          end
          create(:"type_de_champ_#{type_champ}", private: true, libelle: libelle, position: index, procedure: procedure)
        end
        procedure.reload
      end
    end
  end
end
