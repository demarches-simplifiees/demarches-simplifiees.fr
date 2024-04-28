# frozen_string_literal: true

describe DossierProjectionService do
  describe '#project' do
    subject { described_class.project(dossiers_ids, fields) }

    context 'with multiple dossier' do
      let!(:procedure) { create(:procedure, types_de_champ_public: [{}, { type: :linked_drop_down_list }]) }
      let!(:dossier_1) { create(:dossier, procedure: procedure) }
      let!(:dossier_2) { create(:dossier, :en_construction, :archived, procedure: procedure) }
      let!(:dossier_3) { create(:dossier, :en_instruction, procedure: procedure) }

      let(:dossiers_ids) { [dossier_3.id, dossier_1.id, dossier_2.id] }
      let(:fields) do
        procedure.active_revision.types_de_champ_public.map do |type_de_champ|
          {
            "table" => "type_de_champ",
            "column" => type_de_champ.stable_id.to_s
          }
        end
      end

      before do
        dossier_1.champs_public.first.update(value: 'champ_1')
        dossier_1.champs_public.second.update(value: '["test"]')
        dossier_2.champs_public.first.update(value: 'champ_2')
        dossier_3.champs_public.first.destroy
      end

      let(:result) { subject }

      it 'respects the dossiers_ids order, returns state, archived and nil for empty result' do
        expect(result.length).to eq(3)

        expect(result[0].dossier_id).to eq(dossier_3.id)
        expect(result[1].dossier_id).to eq(dossier_1.id)
        expect(result[2].dossier_id).to eq(dossier_2.id)

        expect(result[0].state).to eq('en_instruction')
        expect(result[1].state).to eq('brouillon')
        expect(result[2].state).to eq('en_construction')

        expect(result[0].archived).to be false
        expect(result[1].archived).to be false
        expect(result[2].archived).to be true

        expect(result[0].columns[0]).to be nil
        expect(result[1].columns[0]).to eq('champ_1')
        expect(result[2].columns[0]).to eq('champ_2')
      end
    end

    context 'with commune champ' do
      let!(:procedure) { create(:procedure, types_de_champ_public: [{ type: :communes }]) }
      let!(:dossier) { create(:dossier, procedure:) }

      let(:dossiers_ids) { [dossier.id] }
      let(:fields) do
        [
          {
            "table" => "type_de_champ",
            "column" => procedure.active_revision.types_de_champ_public[0].stable_id.to_s
          }
        ]
      end

      before do
        dossier.champs_public.first.update(code_postal: '63290', external_id: '63102')
      end

      let(:result) { subject }

      it 'returns champ value' do
        expect(result.length).to eq(1)
        expect(result[0].dossier_id).to eq(dossier.id)
        expect(result[0].columns[0]).to eq('Châteldon (63290)')
      end
    end

    context 'attributes by attributes' do
      let(:fields) { [{ "table" => table, "column" => column }] }
      let(:dossiers_ids) { [dossier.id] }

      subject { super()[0].columns[0] }

      context 'for self table' do
        let(:table) { 'self' }

        context 'for created_at column' do
          let(:column) { 'created_at' }
          let(:dossier) { Timecop.freeze(Time.zone.local(1992, 3, 22)) { create(:dossier) } }

          it { is_expected.to eq('22/03/1992') }
        end

        context 'for en_construction_at column' do
          let(:column) { 'en_construction_at' }
          let(:dossier) { create(:dossier, :en_construction, en_construction_at: Time.zone.local(2018, 10, 17)) }

          it { is_expected.to eq('17/10/2018') }
        end

        context 'for depose_at column' do
          let(:column) { 'depose_at' }
          let(:dossier) { create(:dossier, :en_construction, depose_at: Time.zone.local(2018, 10, 17)) }

          it { is_expected.to eq('17/10/2018') }
        end

        context 'for updated_at column' do
          let(:column) { 'updated_at' }
          let(:dossier) { create(:dossier) }

          before { dossier.touch(time: Time.zone.local(2018, 9, 25)) }

          it { is_expected.to eq('25/09/2018') }
        end
      end

      context 'for user table' do
        let(:table) { 'user' }
        let(:column) { 'email' }

        let(:dossier) { create(:dossier, user: create(:user, email: 'bla@yopmail.com')) }

        it { is_expected.to eq('bla@yopmail.com') }
      end

      context 'for individual table' do
        let(:table) { 'individual' }
        let(:procedure) { create(:procedure, :for_individual, :with_type_de_champ, :with_type_de_champ_private) }
        let(:dossier) { create(:dossier, procedure: procedure, individual: build(:individual, nom: 'Martin', prenom: 'Jacques', gender: 'M.')) }

        context 'for prenom column' do
          let(:column) { 'prenom' }

          it { is_expected.to eq('Jacques') }
        end

        context 'for nom column' do
          let(:column) { 'nom' }

          it { is_expected.to eq('Martin') }
        end

        context 'for gender column' do
          let(:column) { 'gender' }

          it { is_expected.to eq('M.') }
        end
      end

      context 'for etablissement table' do
        let(:table) { 'etablissement' }
        let(:column) { 'code_postal' } # All other columns work the same, no extra test required

        let!(:dossier) { create(:dossier, etablissement: create(:etablissement, code_postal: '75008')) }

        it { is_expected.to eq('75008') }
      end

      context 'for groupe_instructeur table' do
        let(:table) { 'groupe_instructeur' }
        let(:column) { 'label' }

        let!(:dossier) { create(:dossier) }

        it { is_expected.to eq('défaut') }
      end

      context 'for followers_instructeurs table' do
        let(:table) { 'followers_instructeurs' }
        let(:column) { 'email' }

        let(:dossier) { create(:dossier) }
        let!(:follow1) { create(:follow, dossier: dossier, instructeur: create(:instructeur, email: 'b@host.fr')) }
        let!(:follow2) { create(:follow, dossier: dossier, instructeur: create(:instructeur, email: 'a@host.fr')) }
        let!(:follow3) { create(:follow, dossier: dossier, instructeur: create(:instructeur, email: 'c@host.fr')) }

        it { is_expected.to eq "a@host.fr, b@host.fr, c@host.fr" }
      end

      context 'for type_de_champ table' do
        let(:table) { 'type_de_champ' }
        let(:dossier) { create(:dossier) }
        let(:column) { dossier.procedure.active_revision.types_de_champ_public.first.stable_id.to_s }

        before { dossier.champs_public.first.update(value: 'kale') }

        it { is_expected.to eq('kale') }
      end

      context 'for type_de_champ_private table' do
        let(:table) { 'type_de_champ_private' }
        let(:dossier) { create(:dossier) }
        let(:column) { dossier.procedure.active_revision.types_de_champ_private.first.stable_id.to_s }

        before { dossier.champs_private.first.update(value: 'quinoa') }

        it { is_expected.to eq('quinoa') }
      end

      context 'for type_de_champ table and value to.s' do
        let(:table) { 'type_de_champ' }
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no }]) }
        let(:dossier) { create(:dossier, procedure: procedure) }
        let(:column) { dossier.procedure.active_revision.types_de_champ_public.first.stable_id.to_s }

        before { dossier.champs_public.first.update(value: 'true') }

        it { is_expected.to eq('Oui') }
      end

      context 'for type_de_champ table and value to.s which needs data field' do
        let(:table) { 'type_de_champ' }
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :address }]) }
        let(:dossier) { create(:dossier, procedure: procedure) }
        let(:column) { dossier.procedure.active_revision.types_de_champ_public.first.stable_id.to_s }

        before { dossier.champs_public.first.update(value: '18 a la bonne rue', data: { 'label' => '18 a la bonne rue', 'departement' => 'd' }) }

        it { is_expected.to eq('18 a la bonne rue') }
      end

      context 'for type_de_champ table: type_de_champ pays which needs external_id field' do
        let(:table) { 'type_de_champ' }
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :pays }]) }
        let(:dossier) { create(:dossier, procedure: procedure) }
        let(:column) { dossier.procedure.active_revision.types_de_champ_public.first.stable_id.to_s }

        around do |example|
          I18n.with_locale(:fr) do
            example.run
          end
        end

        context 'when external id is set' do
          before do
            dossier.champs_public.first.update(external_id: 'GB')
          end

          it { is_expected.to eq('Royaume-Uni') }
        end

        context 'when no external id is set' do
          before do
            dossier.champs_public.first.update(value: "qu'il est beau mon pays")
          end

          it { is_expected.to eq("") }
        end
      end

      context 'for dossier corrections table' do
        let(:table) { 'dossier_corrections' }
        let(:column) { 'resolved_at' }
        let(:dossier) { create(:dossier, :en_construction) }
        subject { described_class.project(dossiers_ids, fields)[0] }

        context "when dossier has pending correction" do
          before { create(:dossier_correction, dossier:) }

          it { expect(subject.pending_correction?).to be(true) }
          it { expect(subject.resolved_corrections?).to eq(false) }
        end

        context "when dossier has a resolved correction" do
          before { create(:dossier_correction, :resolved, dossier:) }

          it { expect(subject.pending_correction?).to eq(false) }
          it { expect(subject.resolved_corrections?).to eq(true) }
        end

        context "when dossier has no correction at all" do
          it { expect(subject.pending_correction?).to eq(false) }
          it { expect(subject.resolved_corrections?).to eq(false) }
        end
      end
    end
  end
end
