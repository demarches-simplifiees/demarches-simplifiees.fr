FactoryBot.define do
  factory :type_de_champ do
    sequence(:libelle) { |n| "Libelle du champ #{n}" }
    sequence(:description) { |n| "description du champ #{n}" }
    type_champ { TypeDeChamp.type_champs.fetch(:text) }
    order_place { 1 }
    mandatory { false }
    add_attribute(:private) { false }

    transient do
      procedure { nil }
      position { nil }
      parent { nil }
    end

    after(:build) do |type_de_champ, evaluator|
      if evaluator.procedure
        type_de_champ.revision = evaluator.procedure.active_revision

        build(:procedure_revision_type_de_champ,
          position: evaluator.position,
          revision: evaluator.procedure.active_revision,
          type_de_champ: type_de_champ)

        if type_de_champ.private?
          type_de_champ.revision.types_de_champ_private << type_de_champ
        else
          type_de_champ.revision.types_de_champ << type_de_champ
        end
      elsif evaluator.parent
        type_de_champ.revision = evaluator.parent.revision
        type_de_champ.order_place = evaluator.position || evaluator.parent.types_de_champ.size
        evaluator.parent.types_de_champ << type_de_champ
      else
        type_de_champ.order_place = evaluator.position
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
    factory :type_de_champ_auto_completion do
      type_champ { TypeDeChamp.type_champs.fetch(:auto_completion) }
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
    factory :type_de_champ_nationalites do
      type_champ { TypeDeChamp.type_champs.fetch(:nationalites) }
    end
    factory :type_de_champ_commune_de_polynesie do
      type_champ { TypeDeChamp.type_champs.fetch(:commune_de_polynesie) }
    end
    factory :type_de_champ_code_postal_de_polynesie do
      type_champ { TypeDeChamp.type_champs.fetch(:code_postal_de_polynesie) }
    end
    factory :type_de_champ_numero_dn do
      type_champ { TypeDeChamp.type_champs.fetch(:numero_dn) }
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
        type_de_champ.piece_justificative_template.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
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
    factory :type_de_champ_carte do
      type_champ { TypeDeChamp.type_champs.fetch(:carte) }
    end
    factory :type_de_champ_te_fenua do
      type_champ { TypeDeChamp.type_champs.fetch(:te_fenua) }
    end
    factory :type_de_champ_repetition do
      type_champ { TypeDeChamp.type_champs.fetch(:repetition) }
      mandatory { true }

      transient do
        types_de_champ { [] }
      end

      after(:build) do |type_de_champ_repetition, evaluator|
        evaluator.types_de_champ.each do |type_de_champ|
          type_de_champ.revision = type_de_champ_repetition.revision
          type_de_champ.order_place = type_de_champ_repetition.types_de_champ.size
          type_de_champ_repetition.types_de_champ << type_de_champ
        end
      end

      trait :with_types_de_champ do
        after(:build) do |type_de_champ, _evaluator|
          build(:type_de_champ, libelle: 'sub type de champ', parent: type_de_champ)
        end
      end
    end
  end
end
