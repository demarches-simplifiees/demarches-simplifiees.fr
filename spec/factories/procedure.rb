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
    ask_birthday { false }
    lien_site_web { "https://mon-site.gouv" }
    path { SecureRandom.uuid }
    association :zone

    groupe_instructeurs { [association(:groupe_instructeur, :default, procedure: instance, strategy: :build)] }
    administrateurs { administrateur.present? ? [administrateur] : [association(:administrateur)] }

    transient do
      administrateur {}
      instructeurs { [] }
      types_de_champ { [] }
      types_de_champ_private { [] }
      updated_at { nil }
      attestation_template { nil }
      dossier_submitted_message { nil }
    end

    after(:build) do |procedure, evaluator|
      initial_revision = build(:procedure_revision, procedure: procedure, attestation_template: evaluator.attestation_template, dossier_submitted_message: evaluator.dossier_submitted_message)
      add_types_de_champs(evaluator.types_de_champ, to: initial_revision, scope: :public)
      add_types_de_champs(evaluator.types_de_champ_private, to: initial_revision, scope: :private)

      if procedure.brouillon?
        procedure.draft_revision = initial_revision
      else
        procedure.published_revision = initial_revision
        procedure.published_revision.published_at = Time.zone.now
        procedure.draft_revision = build(:procedure_revision, from_original: initial_revision)
      end
    end

    after(:create) do |procedure, evaluator|
      evaluator.instructeurs.each { |i| i.assign_to_procedure(procedure) }

      if evaluator.updated_at
        procedure.update_column(:updated_at, evaluator.updated_at)
      end

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
        end
      end
    end

    factory :simple_procedure do
      published

      for_individual { true }

      after(:build) do |procedure, _evaluator|
        build(:type_de_champ, libelle: 'Texte obligatoire', mandatory: true, procedure: procedure)
      end
    end

    trait :with_bulk_message do
      groupe_instructeurs { [association(:groupe_instructeur, :default, :with_bulk_message, procedure: instance, strategy: :build)] }
    end

    trait :with_logo do
      logo { Rack::Test::UploadedFile.new('spec/fixtures/files/logo_test_procedure.png', 'image/png') }
    end
    trait :expirable do
      procedure_expires_when_termine_enabled { true }
    end
    trait :with_path do
      path { generate(:published_path) }
    end

    trait :with_service do
      service { association :service, administrateur: administrateurs.first }
    end

    trait :with_instructeur do
      after(:create) do |procedure, _evaluator|
        procedure.defaut_groupe_instructeur.instructeurs << build(:instructeur)
      end
    end

    trait :routee do
      after(:create) do |procedure, _evaluator|
        procedure.groupe_instructeurs.create(label: 'deuxième groupe')
      end
    end

    trait :for_individual do
      for_individual { true }
    end

    trait :with_auto_archive do
      auto_archive_on { Time.zone.today + 20 }
    end

    trait :with_type_de_champ do
      transient do
        types_de_champ_count { 1 }
      end

      after(:build) do |procedure, evaluator|
        evaluator.types_de_champ_count.times do |position|
          build(:type_de_champ, procedure: procedure, position: position)
        end
      end
    end

    trait :with_type_de_champ_private do
      transient do
        types_de_champ_private_count { 1 }
      end

      after(:build) do |procedure, evaluator|
        evaluator.types_de_champ_private_count.times do |position|
          build(:type_de_champ, :private, procedure: procedure, position: position)
        end
      end
    end

    trait :with_type_de_champ_mandatory do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ, mandatory: true, procedure: procedure)
      end
    end

    trait :with_datetime do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_datetime, mandatory: true, procedure: procedure)
      end
    end

    trait :with_dossier_link do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_dossier_link, procedure: procedure)
      end
    end

    trait :with_siret do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_siret, procedure: procedure)
      end
    end

    trait :with_yes_no do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_yes_no, procedure: procedure)
      end
    end

    trait :with_commune do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_communes, procedure: procedure)
      end
    end

    trait :with_piece_justificative do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_piece_justificative, procedure: procedure)
      end
    end

    trait :with_titre_identite do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_titre_identite, procedure: procedure)
      end
    end

    trait :with_repetition do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_repetition, :with_types_de_champ, procedure: procedure)
      end
    end

    trait :with_private_repetition do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_repetition, :private, procedure: procedure)
      end
    end

    trait :with_number do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_number, procedure: procedure)
      end
    end

    trait :with_phone do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_phone, procedure: procedure)
      end
    end

    trait :with_drop_down_list do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_drop_down_list, :with_other, procedure: procedure)
      end
    end

    trait :with_address do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_address, procedure: procedure)
      end
    end

    trait :with_cnaf do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_cnaf, procedure: procedure)
      end
    end

    trait :with_dgfip do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_dgfip, procedure: procedure)
      end
    end

    trait :with_pole_emploi do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_pole_emploi, procedure: procedure)
      end
    end

    trait :with_mesri do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_mesri, procedure: procedure)
      end
    end

    trait :with_explication do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_explication, procedure: procedure)
      end
    end

    trait :published do
      aasm_state { :publiee }
      path { generate(:published_path) }
      published_at { Time.zone.now }
      unpublished_at { nil }
      closed_at { nil }
    end

    trait :closed do
      published

      aasm_state { :close }
      published_at { Time.zone.now - 1.second }
      closed_at { Time.zone.now }
    end

    trait :unpublished do
      published

      aasm_state { :depubliee }
      published_at { Time.zone.now - 1.second }
      unpublished_at { Time.zone.now }
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
          filename: 'hello.txt',
          # we don't want to run virus scanner on this file
          metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
        )
      end
    end

    trait :with_deliberation do
      after(:create) do |procedure, _evaluator|
        procedure.deliberation.attach(
          io: StringIO.new('Hello World'),
          filename: 'hello.txt',
          # we don't want to run virus scanner on this file
          metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
        )
      end
    end

    trait :with_all_champs_mandatory do
      after(:build) do |procedure, _evaluator|
        TypeDeChamp.type_champs.map.with_index do |(libelle, type_champ), index|
          if libelle == 'drop_down_list'
            libelle = 'simple_drop_down_list'
          end
          build(:"type_de_champ_#{type_champ}", procedure: procedure, mandatory: true, libelle: libelle, position: index)
        end
        build(:type_de_champ_drop_down_list, :long, procedure: procedure, mandatory: true, libelle: 'simple_choice_drop_down_list_long', position: TypeDeChamp.type_champs.size)
        build(:type_de_champ_multiple_drop_down_list, :long, procedure: procedure, mandatory: true, libelle: 'multiple_choice_drop_down_list_long', position: TypeDeChamp.type_champs.size + 1)
      end
    end

    trait :with_all_champs do
      after(:build) do |procedure, _evaluator|
        TypeDeChamp.type_champs.map.with_index do |(libelle, type_champ), index|
          if libelle == 'drop_down_list'
            libelle = 'simple_drop_down_list'
          end
          build(:"type_de_champ_#{type_champ}", procedure: procedure, libelle: libelle, position: index)
        end
      end
    end

    trait :with_all_annotations do
      after(:build) do |procedure, _evaluator|
        TypeDeChamp.type_champs.map.with_index do |(libelle, type_champ), index|
          if libelle == 'drop_down_list'
            libelle = 'simple_drop_down_list'
          end
          build(:"type_de_champ_#{type_champ}", procedure: procedure, private: true, libelle: libelle, position: index)
        end
      end
    end

    trait :with_dossier_submitted_message do
      after(:build) do |procedure, _evaluator|
        build(:dossier_submitted_message, revisions: [procedure.active_revision])
      end
    end
  end
end

def add_types_de_champs(types_de_champ, to: nil, scope: :public)
  revision = to
  association_name = scope == :private ? :revision_types_de_champ_private : :revision_types_de_champ_public

  types_de_champ.each.with_index do |type_de_champ, i|
    type_de_champ.private = (scope == :private)

    revision.public_send(association_name) << build(:procedure_revision_type_de_champ,
                                                                  revision: revision,
                                                                  position: i,
                                                                  type_de_champ: type_de_champ)
  end
end
