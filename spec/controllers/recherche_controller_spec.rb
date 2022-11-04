describe RechercheController, type: :controller do
  let(:procedure) {
    create(:procedure,
                           :published,
                           :for_individual,
                           :with_type_de_champ,
                           :with_type_de_champ_private,
                           types_de_champ_count: 2,
                           types_de_champ_private_count: 2)
  }
  let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }
  let(:instructeur) { create(:instructeur) }

  let(:dossier_with_expert) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }
  let(:avis) { create(:avis, dossier: dossier_with_expert) }

  let(:user) { instructeur.user }

  before do
    instructeur.assign_to_procedure(dossier.procedure)

    dossier.champs_public[0].value = "Name of district A"
    dossier.champs_public[1].value = "Name of city A"
    dossier.champs_private[0].value = "Dossier A is complete"
    dossier.champs_private[1].value = "Dossier A is valid"
    dossier.save!

    dossier_with_expert.champs_public[0].value = "Name of district B"
    dossier_with_expert.champs_public[1].value = "name of city B"
    dossier_with_expert.champs_private[0].value = "Dossier B is incomplete"
    dossier_with_expert.champs_private[1].value = "Dossier B is invalid"
    dossier_with_expert.save!
  end

  describe 'GET #index' do
    before { sign_in(user) }

    subject { get :index, params: { q: query } }

    describe 'by id' do
      context 'when instructeur own the dossier' do
        let(:query) { dossier.id }

        before { subject }

        it { is_expected.to have_http_status(200) }

        it 'returns the expected dossier' do
          expect(assigns(:projected_dossiers).count).to eq(1)
          expect(assigns(:projected_dossiers).first.dossier_id).to eq(dossier.id)
        end
      end

      context 'when expert own the dossier' do
        let(:user) { avis.experts_procedure.expert.user }
        let(:query) { dossier_with_expert.id }

        before { subject }

        it { is_expected.to have_http_status(200) }

        it 'returns the expected dossier' do
          expect(assigns(:projected_dossiers).count).to eq(1)
          expect(assigns(:projected_dossiers).first.dossier_id).to eq(dossier_with_expert.id)
        end
      end

      context 'when instructeur do not own the dossier' do
        let(:dossier2) { create(:dossier, :en_construction) }
        let(:query) { dossier2.id }

        it { is_expected.to have_http_status(200) }

        it 'does not return the dossier' do
          subject
          expect(assigns(:projected_dossiers).count).to eq(0)
          expect(assigns(:not_in_instructor_group_dossiers).count).to eq(0)
        end
      end

      context 'when instructeur is attached to the procedure but is not in the instructor group of the dossier' do
        let!(:gi_p1_1) { GroupeInstructeur.create(label: 'groupe 1', procedure: procedure) }
        let!(:gi_p1_2) { GroupeInstructeur.create(label: 'groupe 2', procedure: procedure) }
        let!(:dossier3) { create(:dossier, :accepte, :with_individual, procedure: procedure, groupe_instructeur: gi_p1_2) }

        before { gi_p1_1.instructeurs << instructeur }

        let(:query) { dossier3.id }

        it { is_expected.to have_http_status(200) }

        it 'does not return the dossier but it returns a message' do
          subject
          expect(assigns(:projected_dossiers).count).to eq(0)
          expect(assigns(:not_in_instructor_group_dossiers)).to eq([dossier3])
        end
      end

      context 'with an id out of range' do
        let(:query) { 123456789876543234567 }

        it { is_expected.to have_http_status(200) }

        it 'does not return the dossier' do
          subject
          expect(assigns(:projected_dossiers).count).to eq(0)
        end
      end
    end

    describe 'by champs' do
      let(:query) { 'district A' }

      before { subject }

      it { is_expected.to have_http_status(200) }

      it 'returns the expected dossier' do
        expect(assigns(:projected_dossiers).count).to eq(1)
        expect(assigns(:projected_dossiers).first.dossier_id).to eq(dossier.id)
      end

      context 'as an expert' do
        let(:user) { avis.experts_procedure.expert.user }
        let(:query) { 'district' }

        it { is_expected.to have_http_status(200) }

        it 'returns only the dossier available to the expert' do
          expect(assigns(:projected_dossiers).count).to eq(1)
          expect(assigns(:projected_dossiers).first.dossier_id).to eq(dossier_with_expert.id)
        end
      end
    end

    describe 'by private annotations' do
      let(:query) { 'invalid' }

      before { subject }

      it { is_expected.to have_http_status(200) }

      it 'returns the expected dossier' do
        expect(assigns(:projected_dossiers).count).to eq(1)
        expect(assigns(:projected_dossiers).first.dossier_id).to eq(dossier_with_expert.id)
      end

      context 'as an expert' do
        let(:user) { avis.experts_procedure.expert.user }

        it { is_expected.to have_http_status(200) }

        it 'does not allow experts to search in private annotations' do
          expect(assigns(:projected_dossiers).count).to eq(0)
        end
      end
    end

    context 'with no query param it does not crash' do
      subject { get :index, params: {} }

      it { is_expected.to have_http_status(200) }

      it 'returns 0 dossier' do
        subject
        expect(assigns(:projected_dossiers).count).to eq(0)
      end
    end
  end
end
