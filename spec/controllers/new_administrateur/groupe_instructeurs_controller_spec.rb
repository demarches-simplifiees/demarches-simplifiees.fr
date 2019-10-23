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

  describe '#show' do
    context 'of a group I belong to' do
      before { get :show, params: { procedure_id: procedure.id, id: gi_1_1.id } }

      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe '#create' do
    before do
      post :create,
        params: {
          procedure_id: procedure.id,
          groupe_instructeur: { label: label }
        }
    end

    context 'with a valid name' do
      let(:label) { "nouveau_groupe" }

      it { expect(flash.notice).to be_present }
      it { expect(response).to redirect_to(procedure_groupe_instructeur_path(procedure, procedure.groupe_instructeurs.last)) }
      it { expect(procedure.groupe_instructeurs.count).to eq(2) }
    end

    context 'with an invalid group name' do
      let(:label) { gi_1_1.label }

      it { expect(response).to render_template(:index) }
      it { expect(procedure.groupe_instructeurs.count).to eq(1) }
      it { expect(flash.alert).to be_present }
    end
  end

  describe '#update' do
    let(:new_name) { 'nouveau nom du groupe' }

    before do
      patch :update,
        params: {
          procedure_id: procedure.id,
          id: gi_1_1.id,
          groupe_instructeur: { label: new_name }
        }
    end

    it { expect(gi_1_1.reload.label).to eq(new_name) }
    it { expect(response).to redirect_to(procedure_groupe_instructeur_path(procedure, gi_1_1)) }
    it { expect(flash.notice).to be_present }

    context 'when the name is already taken' do
      let!(:gi_1_2) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 2') }
      let(:new_name) { gi_1_2.label }

      it { expect(gi_1_1.reload.label).not_to eq(new_name) }
      it { expect(flash.alert).to be_present }
    end
  end
end
