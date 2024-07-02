FactoryBot.define do
  factory :champ_do_not_use, class: 'Champ' do
    stream { 'main' }
    add_attribute(:private) { false }

    factory :champ_do_not_use_text, class: 'Champs::TextChamp' do
      value { 'text' }
    end

    factory :champ_do_not_use_textarea, class: 'Champs::TextareaChamp' do
      value { 'textarea' }
    end

    factory :champ_do_not_use_date, class: 'Champs::DateChamp' do
      value { '2019-07-10' }
    end

    factory :champ_do_not_use_datetime, class: 'Champs::DatetimeChamp' do
      value { '15/09/1962 15:35' }
    end

    factory :champ_do_not_use_number, class: 'Champs::NumberChamp' do
      value { '42' }
    end

    factory :champ_do_not_use_decimal_number, class: 'Champs::DecimalNumberChamp' do
      value { '42.1' }
    end

    factory :champ_do_not_use_integer_number, class: 'Champs::IntegerNumberChamp' do
      value { '42' }
    end

    factory :champ_do_not_use_checkbox, class: 'Champs::CheckboxChamp' do
      value { 'true' }
    end

    factory :champ_do_not_use_civilite, class: 'Champs::CiviliteChamp' do
      value { 'M.' }
    end

    factory :champ_do_not_use_email, class: 'Champs::EmailChamp' do
      value { 'yoda@beta.gouv.fr' }
    end

    factory :champ_do_not_use_phone, class: 'Champs::PhoneChamp' do
      value { '0666666666' }
    end

    factory :champ_do_not_use_address, class: 'Champs::AddressChamp' do
      value { '2 rue des Démarches' }
    end

    factory :champ_do_not_use_yes_no, class: 'Champs::YesNoChamp' do
      value { 'true' }
    end

    factory :champ_do_not_use_drop_down_list, class: 'Champs::DropDownListChamp' do
      transient do
        other { false }
      end
      value { 'val1' }
    end

    factory :champ_do_not_use_multiple_drop_down_list, class: 'Champs::MultipleDropDownListChamp' do
      value { '["val1", "val2"]' }
    end

    factory :champ_do_not_use_linked_drop_down_list, class: 'Champs::LinkedDropDownListChamp' do
      value { '["categorie 1", "choix 1"]' }
    end

    factory :champ_do_not_use_pays, class: 'Champs::PaysChamp' do
      value { 'France' }
    end

    factory :champ_do_not_use_regions, class: 'Champs::RegionChamp' do
      value { 'Guadeloupe' }
    end

    factory :champ_do_not_use_departements, class: 'Champs::DepartementChamp' do
      value { '01' }
    end

    factory :champ_do_not_use_communes, class: 'Champs::CommuneChamp' do
      external_id { '60172' }
      code_postal { '60580' }
    end

    factory :champ_do_not_use_epci, class: 'Champs::EpciChamp' do
      value { 'CC Retz en Valois' }
      external_id { '200071991' }
    end

    factory :champ_do_not_use_header_section, class: 'Champs::HeaderSectionChamp' do
      value { 'une section' }
    end

    factory :champ_do_not_use_explication, class: 'Champs::ExplicationChamp' do
      value { '' }
    end

    factory :champ_do_not_use_dossier_link, class: 'Champs::DossierLinkChamp' do
      value { create(:dossier, :en_construction).id }
    end

    factory :champ_do_not_use_piece_justificative, class: 'Champs::PieceJustificativeChamp' do
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

    factory :champ_do_not_use_titre_identite, class: 'Champs::TitreIdentiteChamp' do
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

    factory :champ_do_not_use_carte, class: 'Champs::CarteChamp' do
      geo_areas { build_list(:geo_area, 2) }
    end

    factory :champ_do_not_use_iban, class: 'Champs::IbanChamp' do
    end

    factory :champ_do_not_use_annuaire_education, class: 'Champs::AnnuaireEducationChamp' do
    end

    factory :champ_do_not_use_cnaf, class: 'Champs::CnafChamp' do
    end

    factory :champ_do_not_use_dgfip, class: 'Champs::DgfipChamp' do
    end

    factory :champ_do_not_use_pole_emploi, class: 'Champs::PoleEmploiChamp' do
    end

    factory :champ_do_not_use_mesri, class: 'Champs::MesriChamp' do
    end

    factory :champ_do_not_use_siret, class: 'Champs::SiretChamp' do
      association :etablissement, factory: [:etablissement]
      value { '44011762001530' }
    end

    factory :champ_do_not_use_rna, class: 'Champs::RNAChamp' do
      value { 'W173847273' }
    end

    factory :champ_do_not_use_engagement_juridique, class: 'Champs::EngagementJuridiqueChamp' do
    end

    factory :champ_do_not_use_cojo, class: 'Champs::COJOChamp' do
    end

    factory :champ_do_not_use_rnf, class: 'Champs::RNFChamp' do
    end

    factory :champ_do_not_use_expression_reguliere, class: 'Champs::ExpressionReguliereChamp' do
    end

    factory :champ_do_not_use_repetition, class: 'Champs::RepetitionChamp' do
      transient do
        rows { 2 }
      end

      after(:build) do |champ_repetition, evaluator|
        revision = champ_repetition.type_de_champ.procedure.active_revision
        parent = revision.revision_types_de_champ.find { _1.type_de_champ == champ_repetition.type_de_champ }
        types_de_champ = revision.revision_types_de_champ.filter { _1.parent == parent }.map(&:type_de_champ)

        evaluator.rows.times do
          row_id = ULID.generate
          champ_repetition.champs << types_de_champ.map do |type_de_champ|
            attrs = { dossier: champ_repetition.dossier, parent: champ_repetition, private: champ_repetition.private?, stable_id: type_de_champ.stable_id, row_id:, type_de_champ: }
            build(:"champ_do_not_use_#{type_de_champ.type_champ}", **attrs)
          end
        end
      end
    end
  end
end
