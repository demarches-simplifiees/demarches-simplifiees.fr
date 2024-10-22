FactoryBot.define do
  factory :champ do
    stream { 'main' }
    add_attribute(:private) { false }

    dossier { association :dossier }
    type_de_champ { association :type_de_champ, procedure: dossier.procedure }

    after(:build) do |champ, _evaluator|
      champ.stable_id = champ.type_de_champ.stable_id
    end

    trait :private do
      add_attribute(:private) { true }
    end

    trait :with_piece_justificative_file do
      after(:build) do |champ, _evaluator|
        champ.piece_justificative_file.attach(
          io: StringIO.new("toto"),
          filename: "toto.txt",
          content_type: "text/plain",
          # we don't want to run virus scanner on this file
          metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
        )
      end
    end

    factory :champ_text, class: 'Champs::TextChamp' do
      type_de_champ { association :type_de_champ_text, procedure: dossier.procedure }
      value { 'text' }
    end

    factory :champ_textarea, class: 'Champs::TextareaChamp' do
      type_de_champ { association :type_de_champ_textarea, procedure: dossier.procedure }
      value { 'textarea' }
    end

    factory :champ_date, class: 'Champs::DateChamp' do
      type_de_champ { association :type_de_champ_date, procedure: dossier.procedure }
      value { '2019-07-10' }
    end

    factory :champ_datetime, class: 'Champs::DatetimeChamp' do
      type_de_champ { association :type_de_champ_datetime, procedure: dossier.procedure }
      value { '15/09/1962 15:35' }
    end

    factory :champ_number, class: 'Champs::NumberChamp' do
      type_de_champ { association :type_de_champ_number, procedure: dossier.procedure }
      value { '42' }
    end

    factory :champ_decimal_number, class: 'Champs::DecimalNumberChamp' do
      type_de_champ { association :type_de_champ_decimal_number, procedure: dossier.procedure }
      value { '42.1' }
    end

    factory :champ_integer_number, class: 'Champs::IntegerNumberChamp' do
      type_de_champ { association :type_de_champ_integer_number, procedure: dossier.procedure }
      value { '42' }
    end

    factory :champ_checkbox, class: 'Champs::CheckboxChamp' do
      type_de_champ { association :type_de_champ_checkbox, procedure: dossier.procedure }
      value { 'true' }
    end

    factory :champ_civilite, class: 'Champs::CiviliteChamp' do
      type_de_champ { association :type_de_champ_civilite, procedure: dossier.procedure }
      value { 'M.' }
    end

    factory :champ_email, class: 'Champs::EmailChamp' do
      type_de_champ { association :type_de_champ_email, procedure: dossier.procedure }
      value { 'yoda@beta.gouv.fr' }
    end

    factory :champ_phone, class: 'Champs::PhoneChamp' do
      type_de_champ { association :type_de_champ_phone, procedure: dossier.procedure }
      value { '0666666666' }
    end

    factory :champ_address, class: 'Champs::AddressChamp' do
      type_de_champ { association :type_de_champ_address, procedure: dossier.procedure }
      value { '2 rue des Démarches' }
    end

    factory :champ_yes_no, class: 'Champs::YesNoChamp' do
      type_de_champ { association :type_de_champ_yes_no, procedure: dossier.procedure }
      value { 'true' }
    end

    factory :champ_drop_down_list, class: 'Champs::DropDownListChamp' do
      transient do
        other { false }
      end

      type_de_champ { association :type_de_champ_drop_down_list, procedure: dossier.procedure, drop_down_other: other }
      value { 'val1' }
    end

    factory :champ_nationalites, class: 'Champs::NationaliteChamp' do
      type_de_champ { association :type_de_champ_nationalites, procedure: dossier.procedure }
      value { 'Française' }
    end

    factory :champ_commune_de_polynesie, class: 'Champs::CommuneDePolynesieChamp' do
      type_de_champ { association :type_de_champ_commune_de_polynesie, procedure: dossier.procedure }
      value { 'Arue - Tahiti - 98701' }
    end

    factory :champ_code_postal_de_polynesie, class: 'Champs::CodePostalDePolynesieChamp' do
      type_de_champ { association :type_de_champ_code_postal_de_polynesie, procedure: dossier.procedure }
      value { '98701 - Arue - Tahiti' }
    end

    factory :champ_numero_dn, class: 'Champs::NumeroDnChamp' do
      type_de_champ { association :type_de_champ_numero_dn, procedure: dossier.procedure }
      # value { '["1234567", "2000-01-01"]' }
      numero_dn { "1234567" }
      date_de_naissance { "2000-01-01" }
    end

    factory :champ_multiple_drop_down_list, class: 'Champs::MultipleDropDownListChamp' do
      type_de_champ { association :type_de_champ_multiple_drop_down_list, procedure: dossier.procedure }
      value { '["val1", "val2"]' }
    end

    factory :champ_linked_drop_down_list, class: 'Champs::LinkedDropDownListChamp' do
      type_de_champ { association :type_de_champ_linked_drop_down_list, procedure: dossier.procedure }
      value { '["categorie 1", "choix 1"]' }
    end

    factory :champ_pays, class: 'Champs::PaysChamp' do
      type_de_champ { association :type_de_champ_pays, procedure: dossier.procedure }
      value { 'France' }
    end

    factory :champ_regions, class: 'Champs::RegionChamp' do
      type_de_champ { association :type_de_champ_regions, procedure: dossier.procedure }
      value { 'Guadeloupe' }
    end

    factory :champ_departements, class: 'Champs::DepartementChamp' do
      type_de_champ { association :type_de_champ_departements, procedure: dossier.procedure }
      value { '01' }
    end

    factory :champ_communes, class: 'Champs::CommuneChamp' do
      type_de_champ { association :type_de_champ_communes, procedure: dossier.procedure }
      external_id { '60172' }
      code_postal { '60580' }
    end

    factory :champ_epci, class: 'Champs::EpciChamp' do
      type_de_champ { association :type_de_champ_epci, procedure: dossier.procedure }
      value { 'CC Retz en Valois' }
      external_id { '200071991' }
    end

    factory :champ_header_section, class: 'Champs::HeaderSectionChamp' do
      type_de_champ { association :type_de_champ_header_section, procedure: dossier.procedure }
      value { 'une section' }
    end
    factory :champ_header_section_level_1, class: 'Champs::HeaderSectionChamp' do
      type_de_champ { association :type_de_champ_header_section_level_1, procedure: dossier.procedure }
      value { 'une section' }
    end
    factory :champ_header_section_level_2, class: 'Champs::HeaderSectionChamp' do
      type_de_champ { association :type_de_champ_header_section_level_2, procedure: dossier.procedure }
      value { 'une section' }
    end
    factory :champ_header_section_level_3, class: 'Champs::HeaderSectionChamp' do
      type_de_champ { association :type_de_champ_header_section_level_3, procedure: dossier.procedure }
      value { 'une section' }
    end

    factory :champ_explication, class: 'Champs::ExplicationChamp' do
      type_de_champ { association :type_de_champ_explication, procedure: dossier.procedure }
      value { '' }
    end

    factory :champ_dossier_link, class: 'Champs::DossierLinkChamp' do
      type_de_champ { association :type_de_champ_dossier_link, procedure: dossier.procedure }
      value { create(:dossier).id }
    end
    factory :champ_without_piece_justificative, class: 'Champs::PieceJustificativeChamp' do
      type_de_champ { association :type_de_champ_piece_justificative, procedure: dossier.procedure }
    end
    factory :champ_piece_justificative, class: 'Champs::PieceJustificativeChamp' do
      type_de_champ { association :type_de_champ_piece_justificative, procedure: dossier.procedure }

      transient do
        size { 4 }
      end

      after(:build) do |champ, evaluator|
        champ.piece_justificative_file.attach(
          io: StringIO.new("x" * evaluator.size),
          filename: "toto.txt",
          content_type: "text/plain",
          # we don't want to run virus scanner on this file
          metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
        )
      end
    end

    factory :champ_piece_justificative_empty, class: 'Champs::PieceJustificativeChamp' do
      type_de_champ { association :type_de_champ_piece_justificative, procedure: dossier.procedure }
    end

    factory :champ_titre_identite, class: 'Champs::TitreIdentiteChamp' do
      type_de_champ { association :type_de_champ_titre_identite, procedure: dossier.procedure }
      transient do
        skip_default_attachment { false }
      end

      after(:build) do |champ, evaluator|
        next if evaluator.skip_default_attachment

        champ.piece_justificative_file.attach(
          io: StringIO.new("toto"),
          filename: "toto.png",
          content_type: "image/png",
          # we don't want to run virus scanner on this file
          metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
        )
      end
    end

    factory :champ_carte, class: 'Champs::CarteChamp' do
      type_de_champ { association :type_de_champ_carte, procedure: dossier.procedure }
    end

    factory :champ_te_fenua, class: 'Champs::TeFenuaChamp' do
      type_de_champ { association :type_de_champ_te_fenua, procedure: dossier.procedure }
    end

    factory :champ_iban, class: 'Champs::IbanChamp' do
      type_de_champ { association :type_de_champ_iban, procedure: dossier.procedure }
    end

    factory :champ_annuaire_education, class: 'Champs::AnnuaireEducationChamp' do
      type_de_champ { association :type_de_champ_annuaire_education, procedure: dossier.procedure }
    end

    factory :champ_referentiel_de_polynesie, class: 'Champs::ReferentielDePolynesieChamp' do
      type_de_champ { association :type_de_champ_referentiel_de_polynesie, procedure: dossier.procedure }
    end

    factory :champ_visa, class: 'Champs::VisaChamp' do
      type_de_champ { association :type_de_champ_visa, procedure: dossier.procedure }
    end

    factory :champ_cnaf, class: 'Champs::CnafChamp' do
      type_de_champ { association :type_de_champ_cnaf, procedure: dossier.procedure }
    end

    factory :champ_dgfip, class: 'Champs::DgfipChamp' do
      type_de_champ { association :type_de_champ_dgfip, procedure: dossier.procedure }
    end

    factory :champ_pole_emploi, class: 'Champs::PoleEmploiChamp' do
      type_de_champ { association :type_de_champ_pole_emploi, procedure: dossier.procedure }
    end

    factory :champ_mesri, class: 'Champs::MesriChamp' do
      type_de_champ { association :type_de_champ_mesri, procedure: dossier.procedure }
    end

    factory :champ_siret, class: 'Champs::SiretChamp' do
      type_de_champ { association :type_de_champ_siret, procedure: dossier.procedure }
      association :etablissement, factory: [:etablissement]
      value { '44011762001530' }
    end

    factory :champ_rna, class: 'Champs::RNAChamp' do
      type_de_champ { association :type_de_champ_rna, procedure: dossier.procedure }
      association :etablissement, factory: [:etablissement]
      value { 'W173847273' }
    end

    factory :champ_engagement_juridique, class: 'Champs::EngagementJuridiqueChamp' do
      type_de_champ { association :type_de_champ_engagement_juridique, procedure: dossier.procedure }
    end

    factory :champ_cojo, class: 'Champs::COJOChamp' do
      type_de_champ { association :type_de_champ_cojo, procedure: dossier.procedure }
    end

    factory :champ_rnf, class: 'Champs::RNFChamp' do
      type_de_champ { association :type_de_champ_rnf, procedure: dossier.procedure }
    end

    factory :champ_expression_reguliere, class: 'Champs::ExpressionReguliereChamp' do
      type_de_champ { association :type_de_champ_expression_reguliere, procedure: dossier.procedure }
    end

    factory :champ_repetition, class: 'Champs::RepetitionChamp' do
      type_de_champ { association :type_de_champ_repetition, procedure: dossier.procedure }

      transient do
        rows { 2 }
      end

      after(:build) do |champ_repetition, evaluator|
        revision = champ_repetition.type_de_champ.procedure&.active_revision || build(:procedure_revision)
        parent = revision.revision_types_de_champ.find { |rtdc| rtdc.type_de_champ == champ_repetition.type_de_champ }
        types_de_champ = revision.revision_types_de_champ.filter { |rtdc| rtdc.parent == parent }.map(&:type_de_champ)

        evaluator.rows.times do
          row_id = ULID.generate
          champ_repetition.champs << types_de_champ.map do |type_de_champ|
            build(:"champ_#{type_de_champ.type_champ}", dossier: champ_repetition.dossier, row_id:, type_de_champ: type_de_champ, parent: champ_repetition, private: champ_repetition.private?)
          end
        end
      end

      trait :without_champs do
        after(:build) do |champ_repetition, _evaluator|
          champ_repetition.champs = []
        end
      end
    end

    factory :champ_repetition_with_piece_jointe, class: 'Champs::RepetitionChamp' do
      type_de_champ { association :type_de_champ_repetition, procedure: dossier.procedure }

      transient do
        rows { 2 }
      end

      after(:build) do |champ_repetition, evaluator|
        types_de_champ = champ_repetition.type_de_champ.types_de_champ
        existing_pj0 = types_de_champ.find { |tdc| tdc.libelle == 'Justificatif de domicile' }
        type_de_champ_pj0 = existing_pj0 || build(
          :type_de_champ_piece_justificative,
          position: 0,
          parent: champ_repetition.type_de_champ,
          libelle: 'Justificatif de domicile'
        )

        existing_pj1 = types_de_champ.find { |tdc| tdc.libelle == 'Carte d\'identité' }
        type_de_champ_pj1 = existing_pj1 || build(
          :type_de_champ_piece_justificative,
          position: 0,
          parent: champ_repetition.type_de_champ,
          libelle: 'Carte d\'identité'
        )

        champ_repetition.type_de_champ.types_de_champ << [type_de_champ_pj0, type_de_champ_pj1]

        evaluator.rows.times do |row|
          champ_repetition.champs << [
            build(:champ_piece_justificative, dossier: champ_repetition.dossier, row: row, type_de_champ: type_de_champ_pj0),
            build(:champ_piece_justificative, dossier: champ_repetition.dossier, row: row, type_de_champ: type_de_champ_pj1)
          ]
        end
      end
    end
  end
end
