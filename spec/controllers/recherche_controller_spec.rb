describe RechercheController, type: :controller do
  let(:procedure) {
    create(:procedure, :published,
                       :for_individual,
                       types_de_champ_public: [{ type: :text }, { type: :text }],
                       types_de_champ_private: [{ type: :text }, { type: :text }])
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

    perform_enqueued_jobs(only: DossierIndexSearchTermsJob)
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
          expect(assigns(:dossier_not_in_instructor_group)).to eq(nil)
        end
      end

      context 'when dossier is brouillon without groupe instructeur' do
        let(:dossier2) { create(:dossier, :brouillon, procedure: procedure) }
        let(:query) { dossier2.id }
        before { dossier2.update(groupe_instructeur_id: nil) }

        it { is_expected.to have_http_status(200) }

        it 'does not return the dossier' do
          subject
          expect(assigns(:projected_dossiers).count).to eq(0)
          expect(assigns(:dossier_not_in_instructor_group)).to eq(nil)
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
          expect(assigns(:dossier_not_in_instructor_group)).to eq(dossier3)
        end
      end

      context 'when dossier is deleted' do
        let!(:deleted_dossier) { DeletedDossier.create_from_dossier(dossier, DeletedDossier.reasons.fetch(:user_request)) }
        let(:query) { deleted_dossier.dossier_id }

        before { subject }

        it { is_expected.to have_http_status(200) }

        it 'does not return the dossier but it returns a message' do
          subject
          expect(assigns(:dossiers_count)).to eq(0)
          expect(assigns(:deleted_dossier)).to eq(deleted_dossier)
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

      it { is_expected.to have_http_status(200) }

      it 'returns the expected dossier' do
        subject
        expect(assigns(:projected_dossiers).count).to eq(1)
        expect(assigns(:projected_dossiers).first.dossier_id).to eq(dossier.id)
      end

      context 'when dossier has notification' do
        before do
          instructeur.follow(dossier)
          dossier.touch(:last_commentaire_updated_at)
        end

        it 'assigns notification' do
          subject
          expect(assigns(:notifications_dossier_ids)).to eq([dossier.id])
        end
      end

      context 'as an expert' do
        let(:user) { avis.experts_procedure.expert.user }
        let(:query) { 'district' }

        it { is_expected.to have_http_status(200) }

        it 'returns only the dossier available to the expert' do
          subject
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
