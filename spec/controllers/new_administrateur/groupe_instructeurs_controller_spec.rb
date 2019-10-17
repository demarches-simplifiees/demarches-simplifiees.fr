describe NewAdministrateur::GroupeInstructeursController, type: :controller do
  render_views

  let(:admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, :published, administrateurs: [admin]) }
  let!(:gi_1_1) { procedure.defaut_groupe_instructeur }

  let(:procedure2) { create(:procedure, :published) }
  let!(:gi_2_2) { procedure2.groupe_instructeurs.create(label: 'groupe instructeur 2 2') }

  before { sign_in(admin.user) }

  describe '#index' do
    context 'of a procedure I own' do
      let!(:gi_1_2) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 2') }

      before { get :index, params: { procedure_id: procedure.id } }

      context 'when a procedure has multiple groups' do
        it { expect(response).to have_http_status(:ok) }
        it { expect(response.body).to include(gi_1_1.label) }
        it { expect(response.body).to include(gi_1_2.label) }
        it { expect(response.body).not_to include(gi_2_2.label) }
      end
    end
  end
end
