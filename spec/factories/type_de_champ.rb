FactoryBot.define do
  factory :type_de_champ do
    sequence(:libelle) { |n| "Libelle du champ #{n}" }
    sequence(:description) { |n| "description du champ #{n}" }
    type_champ { TypeDeChamp.type_champs.fetch(:text) }
    mandatory { false }
    add_attribute(:private) { false }

    transient do
      procedure { nil }
      position { nil }
      types_de_champ { nil }
    end

    after(:build) do |type_de_champ, evaluator|
      if evaluator.procedure.present?
        revision = evaluator.procedure.active_revision
        revision_type_de_champ = build(:procedure_revision_type_de_champ,
          position: evaluator.position,
          revision: revision,
          type_de_champ: type_de_champ)

        if evaluator.types_de_champ.present?
          association = revision_type_de_champ.association(:revision_types_de_champ)
          evaluator.types_de_champ.each.with_index do |type_de_champ, index|
            procedure_revision_type_de_champ = build(:procedure_revision_type_de_champ,
              position: index,
              revision: revision,
              parent: revision_type_de_champ,
              type_de_champ: type_de_champ)
            revision_type_de_champ.revision_types_de_champ << procedure_revision_type_de_champ
            #association.set_inverse_instance(procedure_revision_type_de_champ)
          end
          # revision_type_de_champ.association(:types_de_champ).target = evaluator.types_de_champ
          # type_de_champ.association(:types_de_champ).target = evaluator.types_de_champ
          # pp revision_type_de_champ.types_de_champ
          # pp type_de_champ.types_de_champ
        end

        #type_de_champ.association(:revision_type_de_champ).target = revision_type_de_champ
        #type_de_champ.association(:draft_revision_type_de_champ).target = revision_type_de_champ

        if type_de_champ.private?
          revision.revision_types_de_champ_private << revision_type_de_champ
        else
          revision.revision_types_de_champ << revision_type_de_champ
        end
      elsif evaluator.types_de_champ.present?
        raise "A type de champ repetition can only be created with procedure"
      end
    end

    trait :private do
      add_attribute(:private) { true }
      sequence(:libelle) { |n| "Libelle champ privé #{n}" }
      sequence(:description) { |n| "description du champ privé #{n}" }
    end

    factory :type_de_champ_text do
      type_champ { TypeDeChamp.type_champs.fetch(:text) }
    end
    factory :type_de_champ_textarea do
      type_champ { TypeDeChamp.type_champs.fetch(:textarea) }
    end
    factory :type_de_champ_number do
      type_champ { TypeDeChamp.type_champs.fetch(:number) }
    end
    factory :type_de_champ_decimal_number do
      type_champ { TypeDeChamp.type_champs.fetch(:decimal_number) }
    end
    factory :type_de_champ_integer_number do
      type_champ { TypeDeChamp.type_champs.fetch(:integer_number) }
    end
    factory :type_de_champ_checkbox do
      type_champ { TypeDeChamp.type_champs.fetch(:checkbox) }
    end
    factory :type_de_champ_civilite do
      type_champ { TypeDeChamp.type_champs.fetch(:civilite) }
    end
    factory :type_de_champ_email do
      type_champ { TypeDeChamp.type_champs.fetch(:email) }
    end
    factory :type_de_champ_phone do
      type_champ { TypeDeChamp.type_champs.fetch(:phone) }
    end
    factory :type_de_champ_address do
      type_champ { TypeDeChamp.type_champs.fetch(:address) }
    end
    factory :type_de_champ_yes_no do
      libelle { 'Yes/no' }
      type_champ { TypeDeChamp.type_champs.fetch(:yes_no) }
    end
    factory :type_de_champ_date do
      type_champ { TypeDeChamp.type_champs.fetch(:date) }
    end
    factory :type_de_champ_datetime do
      type_champ { TypeDeChamp.type_champs.fetch(:datetime) }
    end
    factory :type_de_champ_drop_down_list do
      libelle { 'Choix parmi une liste' }
      type_champ { TypeDeChamp.type_champs.fetch(:drop_down_list) }
      drop_down_list_value { "val1\r\nval2\r\n--separateur--\r\nval3" }
      trait :long do
        drop_down_list_value { "alpha\r\nbravo\r\n--separateur--\r\ncharly\r\ndelta\r\necho\r\nfox-trot\r\ngolf" }
      end
      trait :without_selectable_values do
        drop_down_list_value { "\r\n--separateur--\r\n--separateur 2--\r\n \r\n" }
      end
    end
    factory :type_de_champ_multiple_drop_down_list do
      type_champ { TypeDeChamp.type_champs.fetch(:multiple_drop_down_list) }
      drop_down_list_value { "val1\r\nval2\r\n--separateur--\r\nval3" }
      trait :long do
        drop_down_list_value { "alpha\r\nbravo\r\n--separateur--\r\ncharly\r\ndelta\r\necho\r\nfox-trot\r\ngolf" }
      end
    end
    factory :type_de_champ_linked_drop_down_list do
      type_champ { TypeDeChamp.type_champs.fetch(:linked_drop_down_list) }
      drop_down_list_value { "--primary--\nsecondary\n" }
    end
    factory :type_de_champ_pays do
      type_champ { TypeDeChamp.type_champs.fetch(:pays) }
    end
    factory :type_de_champ_regions do
      type_champ { TypeDeChamp.type_champs.fetch(:regions) }
    end
    factory :type_de_champ_departements do
      type_champ { TypeDeChamp.type_champs.fetch(:departements) }
    end
    factory :type_de_champ_communes do
      type_champ { TypeDeChamp.type_champs.fetch(:communes) }
    end
    factory :type_de_champ_engagement do
      type_champ { TypeDeChamp.type_champs.fetch(:engagement) }
    end
    factory :type_de_champ_header_section do
      type_champ { TypeDeChamp.type_champs.fetch(:header_section) }
    end
    factory :type_de_champ_explication do
      type_champ { TypeDeChamp.type_champs.fetch(:explication) }
    end
    factory :type_de_champ_dossier_link do
      libelle { 'Référence autre dossier' }
      type_champ { TypeDeChamp.type_champs.fetch(:dossier_link) }
    end
    factory :type_de_champ_piece_justificative do
      type_champ { TypeDeChamp.type_champs.fetch(:piece_justificative) }

      after(:build) do |type_de_champ, _evaluator|
        type_de_champ.piece_justificative_template.attach(
          io: StringIO.new("toto"),
          filename: "toto.txt",
          content_type: "text/plain",
          # we don't want to run virus scanner on this file
          metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
        )
      end
    end
    factory :type_de_champ_titre_identite do
      type_champ { TypeDeChamp.type_champs.fetch(:titre_identite) }
    end
    factory :type_de_champ_siret do
      type_champ { TypeDeChamp.type_champs.fetch(:siret) }
    end
    factory :type_de_champ_iban do
      type_champ { TypeDeChamp.type_champs.fetch(:iban) }
    end
    factory :type_de_champ_annuaire_education do
      type_champ { TypeDeChamp.type_champs.fetch(:annuaire_education) }
    end
    factory :type_de_champ_cnaf do
      type_champ { TypeDeChamp.type_champs.fetch(:cnaf) }
    end
    factory :type_de_champ_dgfip do
      type_champ { TypeDeChamp.type_champs.fetch(:dgfip) }
    end
    factory :type_de_champ_pole_emploi do
      type_champ { TypeDeChamp.type_champs.fetch(:pole_emploi) }
    end
    factory :type_de_champ_mesri do
      type_champ { TypeDeChamp.type_champs.fetch(:mesri) }
    end
    factory :type_de_champ_carte do
      type_champ { TypeDeChamp.type_champs.fetch(:carte) }
    end
    factory :type_de_champ_repetition do
      type_champ { TypeDeChamp.type_champs.fetch(:repetition) }

      trait :with_types_de_champ do
        types_de_champ { [build(:type_de_champ, libelle: 'sub type de champ')] }
      end
    end
  end
end
