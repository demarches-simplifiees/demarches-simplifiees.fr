describe RechercheController, type: :controller do
  let(:dossier) { create(:dossier, :en_construction, :with_all_annotations) }
  let(:dossier2) { create(:dossier, :en_construction, procedure: dossier.procedure) }
  let(:instructeur) { create(:instructeur) }

  let(:dossier_with_expert) { avis.dossier }
  let(:avis) { create(:avis, dossier: create(:dossier, :en_construction, :with_all_annotations)) }

  let(:user) { instructeur.user }

  before do
    instructeur.assign_to_procedure(dossier.procedure)
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
        let(:dossier3) { create(:dossier, :en_construction) }
        let(:query) { dossier3.id }

        it { is_expected.to have_http_status(200) }

        it 'does not return the dossier' do
          subject
          expect(assigns(:projected_dossiers).count).to eq(0)
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

    describe 'by private annotations' do
      context 'when instructeur search by private annotations' do
        let(:query) { dossier.private_search_terms }

        before { subject }

        it { is_expected.to have_http_status(200) }

        it 'returns the expected dossier' do
          expect(assigns(:projected_dossiers).count).to eq(1)
          expect(assigns(:projected_dossiers).first.dossier_id).to eq(dossier.id)
        end
      end

      context 'when expert search by private annotations' do
        let(:user) { avis.experts_procedure.expert.user }
        let(:query) { dossier_with_expert.private_search_terms }

        before { subject }

        it { is_expected.to have_http_status(200) }

        it 'returns 0 dossiers' do
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
