# frozen_string_literal: true

describe ProcedurePresentation do
  include ActiveSupport::Testing::TimeHelpers

  let(:procedure) { create(:procedure, :published, types_de_champ_public:, types_de_champ_private: [{}]) }
  let(:procedure_id) { procedure.id }
  let(:types_de_champ_public) { [{}] }
  let(:instructeur) { create(:instructeur) }
  let(:assign_to) { create(:assign_to, procedure:, instructeur:) }
  let(:first_type_de_champ) { assign_to.procedure.active_revision.types_de_champ_public.first }
  let(:first_type_de_champ_id) { first_type_de_champ.stable_id.to_s }
  let(:procedure_presentation) {
    create(:procedure_presentation,
      assign_to:,
      displayed_fields: [
        { label: "test1", table: "user", column: "email" },
        { label: "test2", table: "type_de_champ", column: first_type_de_champ_id }
      ],
      sort: { table: "user", column: "email", "order" => "asc" },
      filters: filters)
  }
  let(:procedure_presentation_id) { procedure_presentation.id }
  let(:filters) { { "a-suivre" => [], "suivis" => [{ "label" => "label1", "table" => "self", "column" => "created_at" }] } }

  def to_filter((label, filter)) = FilteredColumn.new(column: procedure.find_column(label: label), filter: filter)

  describe "#displayed_fields" do
    it { expect(procedure_presentation.displayed_fields).to eq([{ "label" => "test1", "table" => "user", "column" => "email" }, { "label" => "test2", "table" => "type_de_champ", "column" => first_type_de_champ_id }]) }
  end

  describe "#sort" do
    it { expect(procedure_presentation.sort).to eq({ "table" => "user", "column" => "email", "order" => "asc" }) }
  end

  describe "#filters" do
    it { expect(procedure_presentation.filters).to eq({ "a-suivre" => [], "suivis" => [{ "label" => "label1", "table" => "self", "column" => "created_at" }] }) }
  end

  describe 'validation' do
    it { expect(build(:procedure_presentation)).to be_valid }

    context 'of displayed columns' do
      it do
        pp = build(:procedure_presentation, displayed_columns: [{ table: "user", column: "reset_password_token", procedure_id: }])
        expect { pp.displayed_columns }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'of filters' do
      it 'validates the filter_column objects' do
        expect(build(:procedure_presentation, "suivis_filters": [{ id: { column_id: "user/email", procedure_id: }, "filter": "not so long filter value" }])).to be_valid
        expect(build(:procedure_presentation, "suivis_filters": [{ id: { column_id: "user/email", procedure_id: }, "filter": "exceedingly long filter value" * 10 }])).to be_invalid
      end
    end
  end

  describe '#sorted_ids' do
    let(:instructeur) { create(:instructeur) }
    let(:assign_to) { create(:assign_to, procedure:, instructeur:) }
    let(:sorted_column) { SortedColumn.new(column:, order:) }
    let(:procedure_presentation) { create(:procedure_presentation, assign_to:, sorted_column:) }

    subject { procedure_presentation.send(:sorted_ids, procedure.dossiers, procedure.dossiers.count) }

    context 'for notifications table' do
      let(:column) { procedure.notifications_column }

      let!(:notified_dossier) { create(:dossier, :en_construction, procedure:) }
      let!(:recent_dossier) { create(:dossier, :en_construction, procedure:) }
      let!(:older_dossier) { create(:dossier, :en_construction, procedure:) }

      before do
        notified_dossier.update!(last_champ_updated_at: Time.zone.local(2018, 9, 20))
        create(:follow, instructeur: instructeur, dossier: notified_dossier, demande_seen_at: Time.zone.local(2018, 9, 10))
        notified_dossier.touch(time: Time.zone.local(2018, 9, 20))
        recent_dossier.touch(time: Time.zone.local(2018, 9, 25))
        older_dossier.touch(time: Time.zone.local(2018, 5, 13))
      end

      context 'in ascending order' do
        let(:order) { 'asc' }

        it { is_expected.to eq([older_dossier, recent_dossier, notified_dossier].map(&:id)) }
      end

      context 'in descending order' do
        let(:order) { 'desc' }

        it { is_expected.to eq([notified_dossier, recent_dossier, older_dossier].map(&:id)) }
      end

      context 'with a dossier terminé' do
        let!(:notified_dossier) { create(:dossier, :accepte, procedure:) }
        let(:order) { 'desc' }

        it { is_expected.to eq([notified_dossier, recent_dossier, older_dossier].map(&:id)) }
      end
    end

    context 'for self table' do
      let(:order) { 'asc' } # Desc works the same, no extra test required

      context 'for created_at column' do
        let!(:column) { procedure.find_column(label: 'Créé le') }
        let!(:recent_dossier) { Timecop.freeze(Time.zone.local(2018, 10, 17)) { create(:dossier, procedure: procedure) } }
        let!(:older_dossier) { Timecop.freeze(Time.zone.local(2003, 11, 11)) { create(:dossier, procedure: procedure) } }

        it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
      end

      context 'for en_construction_at column' do
        let!(:column) { procedure.find_column(label: 'En construction le') }
        let!(:recent_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2018, 10, 17)) }
        let!(:older_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2013, 1, 1)) }

        it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
      end

      context 'for updated_at column' do
        let(:column) { procedure.find_column(label: 'Mis à jour le') }
        let(:recent_dossier) { create(:dossier, procedure: procedure) }
        let(:older_dossier) { create(:dossier, procedure: procedure) }

        before do
          recent_dossier.touch(time: Time.zone.local(2018, 9, 25))
          older_dossier.touch(time: Time.zone.local(2018, 5, 13))
        end

        it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
      end
    end

    context 'for type_de_champ table' do
      context 'with no revisions' do
        let(:column) { procedure.find_column(label: first_type_de_champ.libelle) }

        let(:beurre_dossier) { create(:dossier, procedure:) }
        let(:tartine_dossier) { create(:dossier, procedure:) }

        before do
          beurre_dossier.project_champs_public.first.update(value: 'beurre')
          tartine_dossier.project_champs_public.first.update(value: 'tartine')
        end

        context 'asc' do
          let(:order) { 'asc' }

          it { is_expected.to eq([beurre_dossier, tartine_dossier].map(&:id)) }
        end

        context 'desc' do
          let(:order) { 'desc' }

          it { is_expected.to eq([tartine_dossier, beurre_dossier].map(&:id)) }
        end
      end

      context 'with a revision adding a new type_de_champ' do
        let!(:tdc) { { type_champ: :text, libelle: 'nouveau champ' } }
        let(:column) { procedure.find_column(label: 'nouveau champ') }

        let!(:nothing_dossier) { create(:dossier, procedure:) }
        let!(:beurre_dossier) { create(:dossier, procedure:) }
        let!(:tartine_dossier) { create(:dossier, procedure:) }

        before do
          nothing_dossier
          procedure.draft_revision.add_type_de_champ(tdc)
          procedure.publish_revision!
          beurre_dossier.project_champs_public.last.update(value: 'beurre')
          tartine_dossier.project_champs_public.last.update(value: 'tartine')
        end

        context 'asc' do
          let(:order) { 'asc' }
          it { is_expected.to eq([nothing_dossier, beurre_dossier, tartine_dossier].map(&:id)) }
        end

        context 'desc' do
          let(:order) { 'desc' }
          it { is_expected.to eq([tartine_dossier, beurre_dossier, nothing_dossier].map(&:id)) }
        end
      end
    end

    context 'for type_de_champ_private table' do
      context 'with no revisions' do
        let(:column) { procedure.find_column(label: procedure.active_revision.types_de_champ_private.first.libelle) }

        let(:biere_dossier) { create(:dossier, procedure: procedure) }
        let(:vin_dossier) { create(:dossier, procedure: procedure) }

        before do
          biere_dossier.project_champs_private.first.update(value: 'biere')
          vin_dossier.project_champs_private.first.update(value: 'vin')
        end

        context 'asc' do
          let(:order) { 'asc' }

          it { is_expected.to eq([biere_dossier, vin_dossier].map(&:id)) }
        end

        context 'desc' do
          let(:order) { 'desc' }

          it { is_expected.to eq([vin_dossier, biere_dossier].map(&:id)) }
        end
      end
    end

    context 'for individual table' do
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let(:procedure) { create(:procedure, :for_individual) }

      let!(:first_dossier) { create(:dossier, procedure: procedure, individual: build(:individual, gender: 'M', prenom: 'Alain', nom: 'Antonelli')) }
      let!(:last_dossier) { create(:dossier, procedure: procedure, individual: build(:individual, gender: 'Mme', prenom: 'Zora', nom: 'Zemmour')) }

      context 'for gender column' do
        let(:column) { procedure.find_column(label: 'Civilité') }

        it { is_expected.to eq([first_dossier, last_dossier].map(&:id)) }
      end

      context 'for prenom column' do
        let(:column) { procedure.find_column(label: 'Prénom') }

        it { is_expected.to eq([first_dossier, last_dossier].map(&:id)) }
      end

      context 'for nom column' do
        let(:column) { procedure.find_column(label: 'Nom') }

        it { is_expected.to eq([first_dossier, last_dossier].map(&:id)) }
      end
    end

    context 'for followers_instructeurs table' do
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let!(:dossier_z) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:dossier_a) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:dossier_without_instructeur) { create(:dossier, :en_construction, procedure: procedure) }

      before do
        create(:follow, dossier: dossier_z, instructeur: create(:instructeur, email: 'zythum@exemple.fr'))
        create(:follow, dossier: dossier_a, instructeur: create(:instructeur, email: 'abaca@exemple.fr'))
        create(:follow, dossier: dossier_a, instructeur: create(:instructeur, email: 'abaca2@exemple.fr'))
      end

      context 'for email column' do
        let(:column) { procedure.find_column(label: 'Email instructeur') }

        it { is_expected.to eq([dossier_a, dossier_z, dossier_without_instructeur].map(&:id)) }
      end
    end

    context 'for avis table' do
      let(:column) { procedure.find_column(label: 'Avis oui/non') }
      let(:order) { 'asc' }

      let!(:dossier_yes) { create(:dossier, procedure:) }
      let!(:dossier_no) { create(:dossier, procedure:) }

      before do
        create_list(:avis, 2, dossier: dossier_yes, question_answer: true)
        create(:avis,  dossier: dossier_no, question_answer: true)
        create(:avis,  dossier: dossier_no, question_answer: false)
      end

      it { is_expected.to eq([dossier_no, dossier_yes].map(&:id)) }
    end

    context 'for other tables' do
      # All other columns and tables work the same so it’s ok to test only one
      let(:column) { procedure.find_column(label: 'Code postal') }
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let!(:huitieme_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75008')) }
      let!(:vingtieme_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75020')) }

      it { is_expected.to eq([huitieme_dossier, vingtieme_dossier].map(&:id)) }
    end
  end

  describe '#filtered_ids' do
    let(:procedure_presentation) { create(:procedure_presentation, assign_to:, suivis_filters: filtered_columns) }
    let(:filtered_columns) { filters.map { to_filter(_1) } }
    let(:filters) { [filter] }

    subject { procedure_presentation.send(:filtered_ids, procedure.dossiers.joins(:user), 'suivis') }

    context 'for self table' do
      context 'for created_at column' do
        let(:filter) { ['Créé le', '18/9/2018'] }

        let!(:kept_dossier) { create(:dossier, procedure: procedure, created_at: Time.zone.local(2018, 9, 18, 14, 28)) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, created_at: Time.zone.local(2018, 9, 17, 23, 59)) }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for en_construction_at column' do
        let(:filter) { ['En construction le', '17/10/2018'] }

        let!(:kept_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2018, 10, 17)) }
        let!(:discarded_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2013, 1, 1)) }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for updated_at column' do
        let(:filter) { ['Mis à jour le', '18/9/2018'] }

        let(:kept_dossier) { create(:dossier, procedure: procedure) }
        let(:discarded_dossier) { create(:dossier, procedure: procedure) }

        before do
          kept_dossier.touch(time: Time.zone.local(2018, 9, 18, 14, 28))
          discarded_dossier.touch(time: Time.zone.local(2018, 9, 17, 23, 59))
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for updated_since column' do
        let(:filter) { ['Mis à jour depuis', '18/9/2018'] }

        let(:kept_dossier) { create(:dossier, procedure: procedure) }
        let(:later_dossier) { create(:dossier, procedure: procedure) }
        let(:discarded_dossier) { create(:dossier, procedure: procedure) }

        before do
          kept_dossier.touch(time: Time.zone.local(2018, 9, 18, 14, 28))
          later_dossier.touch(time: Time.zone.local(2018, 9, 19, 14, 28))
          discarded_dossier.touch(time: Time.zone.local(2018, 9, 17, 14, 28))
        end

        it { is_expected.to match_array([kept_dossier.id, later_dossier.id]) }
      end

      context 'for sva_svr_decision_before column' do
        before do
          travel_to Time.zone.local(2023, 6, 10, 10)
        end

        let(:procedure) { create(:procedure, :published, :sva, types_de_champ_public: [{}], types_de_champ_private: [{}]) }
        let(:filter) { ['Date décision SVA avant', '15/06/2023'] }

        let!(:kept_dossier) { create(:dossier, :en_instruction, procedure:, sva_svr_decision_on: Date.current) }
        let!(:later_dossier) { create(:dossier, :en_instruction, procedure:, sva_svr_decision_on: Date.current + 2.days) }
        let!(:discarded_dossier) { create(:dossier, :en_instruction, procedure:, sva_svr_decision_on: Date.current + 10.days) }
        let!(:en_construction_dossier) { create(:dossier, :en_construction, procedure:, sva_svr_decision_on: Date.current + 2.days) }
        let!(:accepte_dossier) { create(:dossier, :accepte, procedure:, sva_svr_decision_on: Date.current + 2.days) }

        it { is_expected.to match_array([kept_dossier.id, later_dossier.id, en_construction_dossier.id]) }
      end

      context 'ignore time of day' do
        let(:filter) { ['En construction le', '17/10/2018 19:30'] }

        let!(:kept_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2018, 10, 17, 15, 56)) }
        let!(:discarded_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2018, 10, 18, 5, 42)) }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for a malformed date' do
        context 'when its a string' do
          let(:filter) { ['Mis à jour le', 'malformed date'] }

          it { is_expected.to match([]) }
        end

        context 'when its a number' do
          let(:filter) { ['Mis à jour le', '177500'] }

          it { is_expected.to match([]) }
        end
      end

      context 'with multiple search values' do
        let(:filters) { [['En construction le', '17/10/2018'], ['En construction le', '19/10/2018']] }

        let!(:kept_dossier) { create(:dossier, :en_construction, procedure:, en_construction_at: Time.zone.local(2018, 10, 17)) }
        let!(:other_kept_dossier) { create(:dossier, :en_construction, procedure:, en_construction_at: Time.zone.local(2018, 10, 19)) }
        let!(:discarded_dossier) { create(:dossier, :en_construction, procedure:, en_construction_at: Time.zone.local(2013, 1, 1)) }

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end

      context 'with multiple state filters' do
        let(:filters) { [['Statut', 'en_construction'], ['Statut', 'en_instruction']] }

        let!(:kept_dossier) { create(:dossier, :en_construction, procedure:) }
        let!(:other_kept_dossier) { create(:dossier, :en_instruction, procedure:) }
        let!(:discarded_dossier) { create(:dossier, :accepte, procedure:) }

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end

      context 'with en_construction state filters' do
        let(:filter) { ['Statut', 'en_construction'] }

        let!(:en_construction) { create(:dossier, :en_construction, procedure:) }
        let!(:en_construction_with_correction) { create(:dossier, :en_construction, procedure:) }
        let!(:correction) { create(:dossier_correction, dossier: en_construction_with_correction) }
        it 'excludes dossier en construction with pending correction' do
          is_expected.to contain_exactly(en_construction.id)
        end
      end
    end

    context 'for type_de_champ table' do
      let(:filter) { [type_de_champ.libelle, 'keep'] }

      let(:kept_dossier) { create(:dossier, procedure: procedure) }
      let(:discarded_dossier) { create(:dossier, procedure: procedure) }
      let(:type_de_champ) { procedure.active_revision.types_de_champ_public.first }

      context 'with single value' do
        before do
          kept_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(value: 'keep me')
          discarded_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(value: 'discard me')
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'with multiple search values' do
        let(:filters) { [[type_de_champ.libelle, 'keep'], [type_de_champ.libelle, 'and']] }
        let(:other_kept_dossier) { create(:dossier, procedure: procedure) }

        before do
          kept_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(value: 'keep me')
          discarded_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(value: 'discard me')
          other_kept_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(value: 'and me too')
        end

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end

      context 'with yes_no type_de_champ' do
        let(:filter) { [type_de_champ.libelle, 'true'] }
        let(:types_de_champ_public) { [{ type: :yes_no }] }

        before do
          kept_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(value: 'true')
          discarded_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(value: 'false')
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'with departement type_de_champ' do
        let(:filter) { [type_de_champ.libelle, '13'] }
        let(:types_de_champ_public) { [{ type: :departements }] }

        before do
          kept_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(external_id: '13')
          discarded_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(external_id: '69')
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'with enum type_de_champ' do
        let(:filter) { [type_de_champ.libelle, 'Favorable'] }
        let(:types_de_champ_public) { [{ type: :drop_down_list, options: ['Favorable', 'Defavorable'] }] }

        before do
          kept_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(value: 'Favorable')
          discarded_dossier.champs.find_by(stable_id: type_de_champ.stable_id).update(external_id: 'Defavorable')
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end
    end

    context 'for type_de_champ_private table' do
      let(:filter) { [type_de_champ_private.libelle, 'keep'] }

      let(:kept_dossier) { create(:dossier, procedure: procedure) }
      let(:discarded_dossier) { create(:dossier, procedure: procedure) }
      let(:type_de_champ_private) { procedure.active_revision.types_de_champ_private.first }

      before do
        kept_dossier.champs.find_by(stable_id: type_de_champ_private.stable_id).update(value: 'keep me')
        discarded_dossier.champs.find_by(stable_id: type_de_champ_private.stable_id).update(value: 'discard me')
      end

      it { is_expected.to contain_exactly(kept_dossier.id) }
    end

    context 'for type_de_champ using AddressableColumnConcern' do
      let(:column) { filtered_columns.first.column }
      let(:types_de_champ_public) { [{ type: :rna, stable_id: 1, libelle: 'rna' }] }
      let(:type_de_champ) { procedure.active_revision.types_de_champ.first }
      let(:kept_dossier) { create(:dossier, procedure: procedure) }

      context "when searching by postal_code (text)" do
        let(:value) { "60580" }
        let(:filter) { ["rna – code postal (5 chiffres)", value] }

        before do
          kept_dossier.project_champs_public.find { _1.stable_id == 1 }.update(value_json: { "postal_code" => value })
          create(:dossier, procedure: procedure).project_champs_public.find { _1.stable_id == 1 }.update(value_json: { "postal_code" => "unknown" })
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }

        it 'describes column' do
          expect(column.type).to eq(:text)
          expect(column.options_for_select).to eq([])
        end
      end

      context "when searching by departement_code (enum)" do
        let(:value) { "99" }
        let(:filter) { ["rna – département", value] }

        before do
          kept_dossier.project_champs_public.find { _1.stable_id == 1 }.update(value_json: { "departement_code" => value })
          create(:dossier, procedure: procedure).project_champs_public.find { _1.stable_id == 1 }.update(value_json: { "departement_code" => "unknown" })
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }

        it 'describes column' do
          expect(column.type).to eq(:enum)
          expect(column.options_for_select.first).to eq(["99 – Etranger", "99"])
        end
      end

      context "when searching by region_name" do
        let(:value) { "60" }
        let(:filter) { ["rna – region", value] }

        before do
          kept_dossier.project_champs_public.find { _1.stable_id == 1 }.update(value_json: { "region_name" => value })
          create(:dossier, procedure: procedure).project_champs_public.find { _1.stable_id == 1 }.update(value_json: { "region_name" => "unknown" })
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }

        it 'describes column' do
          expect(column.type).to eq(:enum)
          expect(column.options_for_select.first).to eq(["Auvergne-Rhône-Alpes", "Auvergne-Rhône-Alpes"])
        end
      end
    end

    context 'for etablissement table' do
      context 'for entreprise_date_creation column' do
        let(:filter) { ['Date de création', '21/6/2018'] }

        let!(:kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, entreprise_date_creation: Time.zone.local(2018, 6, 21))) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, entreprise_date_creation: Time.zone.local(2008, 6, 21))) }

        it { is_expected.to contain_exactly(kept_dossier.id) }

        context 'with multiple search values' do
          let(:filters) { [['Date de création', '21/6/2016'], ['Date de création', '21/6/2018']] }

          let!(:other_kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, entreprise_date_creation: Time.zone.local(2016, 6, 21))) }

          it 'returns every dossier that matches any of the search criteria for a given column' do
            is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
          end
        end
      end

      context 'for code_postal column' do
        # All columns except entreprise_date_creation work exacly the same, just testing one

        let(:filter) { ['Code postal', '75017'] }

        let!(:kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75017')) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '25000')) }

        it { is_expected.to contain_exactly(kept_dossier.id) }

        context 'with multiple search values' do
          let(:filters) { [['Code postal', '75017'], ['Code postal', '88100']] }

          let!(:other_kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '88100')) }

          it 'returns every dossier that matches any of the search criteria for a given column' do
            is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
          end
        end
      end
    end

    context 'for user table' do
      let(:filter) { ['Demandeur', 'keepmail'] }

      let!(:kept_dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'me@keepmail.com')) }
      let!(:discarded_dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'me@discard.com')) }

      it { is_expected.to contain_exactly(kept_dossier.id) }

      context 'with multiple search values' do
        let(:filters) { [['Demandeur', 'keepmail'], ['Demandeur', 'beta.gouv.fr']] }

        let!(:other_kept_dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'bazinga@beta.gouv.fr')) }

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end
    end

    context 'for individual table' do
      let(:procedure) { create(:procedure, :for_individual) }
      let!(:kept_dossier) { create(:dossier, procedure: procedure, individual: build(:individual, gender: 'Mme', prenom: 'Josephine', nom: 'Baker')) }
      let!(:discarded_dossier) { create(:dossier, procedure: procedure, individual: build(:individual, gender: 'M', prenom: 'Jean', nom: 'Tremblay')) }

      context 'for gender column' do
        let(:filter) { ['Civilité', 'Mme'] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for prenom column' do
        let(:filter) { ['Prénom', 'Josephine'] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for nom column' do
        let(:filter) { ['Nom', 'Baker'] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'with multiple search values' do
        let(:filters) { [['Prénom', 'Josephine'], ['Prénom', 'Romuald']] }

        let!(:other_kept_dossier) { create(:dossier, procedure: procedure, individual: build(:individual, gender: 'M', prenom: 'Romuald', nom: 'Pistis')) }

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end
    end

    context 'for followers_instructeurs table' do
      let(:filter) { ['Email instructeur', 'keepmail'] }

      let!(:kept_dossier) { create(:dossier, procedure: procedure) }
      let!(:discarded_dossier) { create(:dossier, procedure: procedure) }

      before do
        create(:follow, dossier: kept_dossier, instructeur: create(:instructeur, email: 'me@keepmail.com'))
        create(:follow, dossier: discarded_dossier, instructeur: create(:instructeur, email: 'me@discard.com'))
      end

      it { is_expected.to contain_exactly(kept_dossier.id) }

      context 'with multiple search values' do
        let(:filters) { [['Email instructeur', 'keepmail'], ['Email instructeur', 'beta.gouv.fr']] }

        let(:other_kept_dossier) { create(:dossier, procedure:) }

        before do
          create(:follow, dossier: other_kept_dossier, instructeur: create(:instructeur, email: 'bazinga@beta.gouv.fr'))
        end

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end
    end

    context 'for groupe_instructeur table' do
      let(:filter) { ['Groupe instructeur', procedure.defaut_groupe_instructeur.id.to_s] }

      let!(:gi_2) { create(:groupe_instructeur, label: 'gi2', procedure:) }
      let!(:gi_3) { create(:groupe_instructeur, label: 'gi3', procedure:) }

      let!(:kept_dossier) { create(:dossier, :en_construction, procedure:) }
      let!(:discarded_dossier) { create(:dossier, :en_construction, procedure:, groupe_instructeur: gi_2) }

      it { is_expected.to contain_exactly(kept_dossier.id) }

      context 'with multiple search values' do
        let(:filters) { [['Groupe instructeur', procedure.defaut_groupe_instructeur.id.to_s], ['Groupe instructeur', gi_3.id.to_s]] }

        let!(:other_kept_dossier) { create(:dossier, procedure:, groupe_instructeur: gi_3) }

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end
    end
  end

  describe "#human_value_for_filter" do
    let(:filtered_column) { to_filter([first_type_de_champ.libelle, "true"]) }

    subject do
      procedure_presentation.human_value_for_filter(filtered_column)
    end

    context 'when type_de_champ text' do
      it 'should passthrough value' do
        expect(subject).to eq("true")
      end
    end

    context 'when type_de_champ yes_no' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no }]) }

      it 'should transform value' do
        expect(subject).to eq("oui")
      end
    end

    context 'when filter is state' do
      let(:filtered_column) { to_filter(['Statut', "en_construction"]) }

      it 'should get i18n value' do
        expect(subject).to eq("En construction")
      end
    end

    context 'when filter is a date' do
      let(:filtered_column) { to_filter(['Créé le', "15/06/2023"]) }

      it 'should get formatted value' do
        expect(subject).to eq("15/06/2023")
      end
    end
  end

  describe '#filtered_sorted_ids' do
    let(:procedure_presentation) { create(:procedure_presentation, assign_to:) }

    subject { procedure_presentation.filtered_sorted_ids(dossiers, statut) }

    context 'with no filters' do
      let(:statut) { 'suivis' }
      let(:dossiers) { procedure.dossiers }

      before do
        create(:follow, dossier: en_construction_dossier, instructeur: procedure_presentation.instructeur)
        create(:follow, dossier: accepte_dossier, instructeur: procedure_presentation.instructeur)
      end

      let(:en_construction_dossier) { create(:dossier, :en_construction, procedure:) }
      let(:accepte_dossier) { create(:dossier, :accepte, procedure:) }

      it { is_expected.to contain_exactly(en_construction_dossier.id) }
    end

    context 'with mocked sorted_ids' do
      let(:dossier_1) { create(:dossier) }
      let(:dossier_2) { create(:dossier) }
      let(:dossier_3) { create(:dossier) }
      let(:dossiers) { Dossier.where(id: [dossier_1, dossier_2, dossier_3].map(&:id)) }

      let(:sorted_ids) { [dossier_2, dossier_3, dossier_1].map(&:id) }
      let(:statut) { 'tous' }

      before do
        expect(procedure_presentation).to receive(:sorted_ids).and_return(sorted_ids)
      end

      it { is_expected.to eq(sorted_ids) }

      context 'when a filter is present' do
        let(:filtered_ids) { [dossier_1, dossier_2, dossier_3].map(&:id) }

        before do
          procedure_presentation.tous_filters = [to_filter(['Statut', 'en_construction'])]
          expect(procedure_presentation).to receive(:filtered_ids).and_return(filtered_ids)
        end

        it { is_expected.to eq(sorted_ids) }
      end
    end
  end

  describe '#update_displayed_fields' do
    let(:en_construction_column) { procedure.find_column(label: 'En construction le') }
    let(:mise_a_jour_column) { procedure.find_column(label: 'Mis à jour le') }

    let(:procedure_presentation) do
      create(:procedure_presentation, assign_to:).tap do |pp|
        pp.update(sorted_column: SortedColumn.new(column: procedure.find_column(label: 'Demandeur'), order: 'desc'))
      end
    end

    subject do
      procedure_presentation.update(displayed_columns: [
        en_construction_column.id, mise_a_jour_column.id
      ])
    end

    it 'should update displayed_fields' do
      expect(procedure_presentation.displayed_columns).to eq(procedure.default_displayed_columns)

      subject

      expect(procedure_presentation.displayed_columns).to eq([
        en_construction_column, mise_a_jour_column
      ])
    end
  end
end
