describe Champs::DossierLinkController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, :with_dossier_link) }

  describe '#show' do
    let(:dossier) { create(:dossier, user: user, procedure: procedure) }
    let(:champ) { dossier.champs_public.first }

    context 'when user is connected' do
      render_views
      before { sign_in user }

      let(:champs_public_attributes) do
        champ_attributes = []
        champ_attributes[champ.id] = { value: dossier_id }
        champ_attributes
      end
      let(:params) do
        {
          champ_id: champ.id,
          dossier: {
            champs_public_attributes: champs_public_attributes
          }
        }
      end
      let(:dossier_id) { dossier.id }

      context 'when the dossier exist' do
        before do
          get :show, params: params, format: :turbo_stream
        end

        it 'renders the procedure name' do
          expect(response.body).to include('Dossier en brouillon')
          expect(response.body).to include(procedure.libelle)
          expect(response.body).to include(procedure.organisation)
          expect(response.body).to include(ActionView::RecordIdentifier.dom_id(champ, :help_block))
        end
      end

      context 'when the dossier does not exist' do
        let(:dossier_id) { '13' }
        before do
          get :show, params: params, format: :turbo_stream
        end

        it 'renders error message' do
          expect(response.body).to include('Ce dossier est inconnu')
          expect(response.body).to include(ActionView::RecordIdentifier.dom_id(champ, :help_block))
        end
      end
    end

    context 'when user is not connected' do
      before do
        get :show, params: { champ_id: champ.id }, format: :turbo_stream
      end

      it { expect(response.code).to eq('401') }
    end
  end
end
