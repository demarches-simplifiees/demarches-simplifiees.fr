FactoryBot.define do
  sequence(:published_path) { |n| "fake_path#{n}" }

  factory :procedure do
    sequence(:libelle) { |n| "Procedure #{n}" }
    description { "Demande de subvention à l'intention des associations" }
    organisation { "Orga DINUM" }
    cadre_juridique { "un cadre juridique important" }
    published_at { nil }
    duree_conservation_dossiers_dans_ds { 3 }
    max_duree_conservation_dossiers_dans_ds { Procedure::OLD_MAX_DUREE_CONSERVATION }
    ask_birthday { false }
    lien_site_web { "https://mon-site.gouv" }
    path { SecureRandom.uuid }

    groupe_instructeurs { [association(:groupe_instructeur, :default, procedure: instance, strategy: :build)] }
    administrateurs { administrateur.present? ? [administrateur] : [association(:administrateur)] }

    transient do
      administrateur {}
      instructeurs { [] }
      types_de_champ_public { [] }
      types_de_champ_private { [] }
      updated_at { nil }
      dossier_submitted_message { nil }
    end

    after(:build) do |procedure, evaluator|
      initial_revision = build(:procedure_revision, procedure: procedure, dossier_submitted_message: evaluator.dossier_submitted_message)

      if evaluator.types_de_champ_public.present?
        if !evaluator.types_de_champ_public.first.is_a?(Hash)
          raise "types_de_champ_public must be an array of hashes"
        end
        build_types_de_champ(evaluator.types_de_champ_public, revision: initial_revision, scope: :public)
      end

      if evaluator.types_de_champ_private.present?
        if !evaluator.types_de_champ_private.first.is_a?(Hash)
          raise "types_de_champ_private must be an array of hashes"
        end
        build_types_de_champ(evaluator.types_de_champ_private, revision: initial_revision, scope: :private)
      end

      if procedure.brouillon?
        procedure.draft_revision = initial_revision
      else
        procedure.published_revision = initial_revision
        procedure.published_revision.published_at = Time.zone.now
        procedure.draft_revision = build(:procedure_revision, from_original: initial_revision)
      end
    end

    before(:create) do |procedure, _evaluator|
      procedure.revisions.each do |revision|
        revision.association(:types_de_champ).reset
        revision.association(:types_de_champ_public).reset
        revision.association(:types_de_champ_private).reset
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

    trait :with_rna do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_rna, procedure: procedure)
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
    trait :with_carte do
      after(:build) do |procedure, _evaluator|
        build(:type_de_champ_carte, procedure: procedure)
      end
    end

    trait :published do
      aasm_state { :publiee }
      path { generate(:published_path) }
      published_at { Time.zone.now }
      unpublished_at { nil }
      closed_at { nil }
      zones { [association(:zone, strategy: :build)] }
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
          if type_champ == 'repetition'
            build(:type_de_champ_repetition, :with_types_de_champ, procedure: procedure, mandatory: true, libelle: libelle, position: index)
          else
            build(:"type_de_champ_#{type_champ}", procedure: procedure, mandatory: true, libelle: libelle, position: index)
          end
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
          if type_champ == 'repetition'
            build(:type_de_champ_repetition, :with_types_de_champ, procedure: procedure, libelle: libelle, position: index)
          else
            build(:"type_de_champ_#{type_champ}", procedure: procedure, libelle: libelle, position: index)
          end
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

def build_types_de_champ(types_de_champ, revision:, scope: :public, parent: nil)
  types_de_champ.deep_dup.each.with_index do |type_de_champ_attributes, i|
    type = TypeDeChamp.type_champs.fetch(type_de_champ_attributes.delete(:type) || :text).to_sym
    position = type_de_champ_attributes.delete(:position) || i
    children = type_de_champ_attributes.delete(:children)
    options = type_de_champ_attributes.delete(:options)
    layers = type_de_champ_attributes.delete(:layers)

    if !options.nil?
      if type == :drop_down_list
        type_de_champ_attributes[:drop_down_other] = options.delete(:other).present?
      end

      if type.in?([:drop_down_list, :multiple_drop_down_list, :linked_drop_down_list])
        type_de_champ_attributes[:drop_down_list_value] = options.join("\r\n")
      end
    end

    if type == :linked_drop_down_list
      type_de_champ_attributes[:drop_down_secondary_libelle] = type_de_champ_attributes.delete(:secondary_libelle)
      type_de_champ_attributes[:drop_down_secondary_description] = type_de_champ_attributes.delete(:secondary_description)
    end

    if type == :carte && layers.present?
      type_de_champ_attributes[:editable_options] = layers.index_with { '1' }
    end

    type_de_champ = if scope == :private
      build(:"type_de_champ_#{type}", :private, no_coordinate: true, **type_de_champ_attributes)
    else
      build(:"type_de_champ_#{type}", no_coordinate: true, **type_de_champ_attributes)
    end
    coordinate = build(:procedure_revision_type_de_champ,
      revision: revision,
      type_de_champ: type_de_champ,
      position: position,
      parent: parent)

    revision.association(:revision_types_de_champ).target << coordinate

    if parent.present?
      parent.association(:revision_types_de_champ).target << coordinate
    end

    if type_de_champ.repetition? && children.present?
      build_types_de_champ(children, revision: revision, scope: scope, parent: coordinate)
    end
  end

  if parent.present?
    parent.association(:revision_types_de_champ).target.sort_by!(&:position)
  else
    revision_types_de_champ_private, revision_types_de_champ_public = revision.revision_types_de_champ.partition(&:private?)

    root_revision_types_de_champ_public, child_revision_types_de_champ_public = revision_types_de_champ_public.partition { |coordinate| coordinate.parent.nil? }
    root_revision_types_de_champ_private, child_revision_types_de_champ_private = revision_types_de_champ_private.partition { |coordinate| coordinate.parent.nil? }
    revision.association(:revision_types_de_champ_public).target = root_revision_types_de_champ_public.sort_by(&:position)
    revision.association(:revision_types_de_champ_private).target = root_revision_types_de_champ_private.sort_by(&:position)
    revision.association(:revision_types_de_champ).target = revision.revision_types_de_champ_public +
      revision.revision_types_de_champ_private +
      child_revision_types_de_champ_public.sort_by(&:parent).sort_by(&:position) +
      child_revision_types_de_champ_private.sort_by(&:parent).sort_by(&:position)

    revision.association(:types_de_champ).target = revision.revision_types_de_champ.map(&:type_de_champ)
    revision.association(:types_de_champ_public).target = revision.revision_types_de_champ_public.map(&:type_de_champ)
    revision.association(:types_de_champ_private).target = revision.revision_types_de_champ_private.map(&:type_de_champ)
  end
end
