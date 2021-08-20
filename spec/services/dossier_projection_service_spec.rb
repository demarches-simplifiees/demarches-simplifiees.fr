describe DossierProjectionService do
  describe '#project' do
    subject { described_class.project(dossiers_ids, fields) }

    context 'with multiple dossier' do
      let!(:procedure) { create(:procedure, :with_type_de_champ) }
      let!(:dossier_1) { create(:dossier, procedure: procedure) }
      let!(:dossier_2) { create(:dossier, :en_construction, :archived, procedure: procedure) }
      let!(:dossier_3) { create(:dossier, :en_instruction, procedure: procedure) }

      let(:dossiers_ids) { [dossier_3.id, dossier_1.id, dossier_2.id] }
      let(:fields) do
        [
          {
            "table" => "type_de_champ",
            "column" => procedure.types_de_champ[0].stable_id.to_s
          }
        ]
      end

      before do
        dossier_1.champs.first.update(value: 'champ_1')
        dossier_2.champs.first.update(value: 'champ_2')
        dossier_3.champs.first.destroy
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
        let(:dossier) { create(:dossier, procedure: procedure, individual: create(:individual, nom: 'Martin', prenom: 'Jacques', gender: 'M.')) }

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
        let!(:follow1) { create(:follow, dossier: dossier, instructeur: create(:instructeur, email: 'b@host')) }
        let!(:follow2) { create(:follow, dossier: dossier, instructeur: create(:instructeur, email: 'a@host')) }
        let!(:follow3) { create(:follow, dossier: dossier, instructeur: create(:instructeur, email: 'c@host')) }

        it { is_expected.to eq "a@host, b@host, c@host" }
      end

      context 'for type_de_champ table' do
        let(:table) { 'type_de_champ' }
        let(:dossier) { create(:dossier) }
        let(:column) { dossier.procedure.types_de_champ.first.stable_id.to_s }

        before { dossier.champs.first.update(value: 'kale') }

        it { is_expected.to eq('kale') }
      end

      context 'for type_de_champ_private table' do
        let(:table) { 'type_de_champ_private' }
        let(:dossier) { create(:dossier) }
        let(:column) { dossier.procedure.types_de_champ_private.first.stable_id.to_s }

        before { dossier.champs_private.first.update(value: 'quinoa') }

        it { is_expected.to eq('quinoa') }
      end

      context 'for type_de_champ table and value to.s' do
        let(:table) { 'type_de_champ' }
        let(:procedure) { create(:procedure, :with_yes_no) }
        let(:dossier) { create(:dossier, procedure: procedure) }
        let(:column) { dossier.procedure.types_de_champ.first.stable_id.to_s }

        before { dossier.champs.first.update(value: 'true') }

        it { is_expected.to eq('Oui') }
      end

      context 'for type_de_champ table and value to.s which needs data field' do
        let(:table) { 'type_de_champ' }
        let(:procedure) { create(:procedure, :with_address) }
        let(:dossier) { create(:dossier, procedure: procedure) }
        let(:column) { dossier.procedure.types_de_champ.first.stable_id.to_s }

        before { dossier.champs.first.update(data: { 'label' => '18 a la bonne rue', 'departement' => 'd' }) }

        it { is_expected.to eq('18 a la bonne rue') }
      end
    end
  end
end
