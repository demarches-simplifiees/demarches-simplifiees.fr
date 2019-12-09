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

  describe '#add_instructeur' do
    let!(:instructeur) { create(:instructeur) }
    before do
      gi_1_1.instructeurs << instructeur

      post :add_instructeur,
        params: {
          procedure_id: procedure.id,
          id: gi_1_1.id,
          emails: new_instructeur_emails
        }
    end

    context 'of a news instructeurs' do
      let(:new_instructeur_emails) { ['new_i1@mail.com', 'new_i2@mail.com'] }

      it { expect(gi_1_1.instructeurs.pluck(:email)).to include(*new_instructeur_emails) }
      it { expect(flash.notice).to be_present }
      it { expect(response).to redirect_to(procedure_groupe_instructeur_path(procedure, gi_1_1)) }
    end

    context 'of an instructeur already in the group' do
      let(:new_instructeur_emails) { [instructeur.email] }

      it { expect(response).to redirect_to(procedure_groupe_instructeur_path(procedure, procedure.defaut_groupe_instructeur)) }
    end

    context 'of badly formed email' do
      let(:new_instructeur_emails) { ['badly_formed_email'] }

      it { expect(flash.alert).to be_present }
      it { expect(response).to redirect_to(procedure_groupe_instructeur_path(procedure, procedure.defaut_groupe_instructeur)) }
    end

    context 'of an empty string' do
      let(:new_instructeur_emails) { '' }

      it { expect(response).to redirect_to(procedure_groupe_instructeur_path(procedure, procedure.defaut_groupe_instructeur)) }
    end
  end

  describe '#remove_instructeur' do
    let!(:instructeur) { create(:instructeur) }

    before { gi_1_1.instructeurs << admin.instructeur << instructeur }

    def remove_instructeur(instructeur)
      delete :remove_instructeur,
        params: {
          procedure_id: procedure.id,
          id: gi_1_1.id,
          instructeur: { id: instructeur.id }
        }
    end

    context 'when there are many instructeurs' do
      before { remove_instructeur(admin.instructeur) }

      it { expect(gi_1_1.instructeurs).to include(instructeur) }
      it { expect(gi_1_1.reload.instructeurs.count).to eq(1) }
      it { expect(response).to redirect_to(procedure_groupe_instructeur_path(procedure, gi_1_1)) }
    end

    context 'when there is only one instructeur' do
      before do
        remove_instructeur(admin.instructeur)
        remove_instructeur(instructeur)
      end

      it { expect(gi_1_1.instructeurs).to include(instructeur) }
      it { expect(gi_1_1.instructeurs.count).to eq(1) }
      it { expect(flash.alert).to eq('Suppression impossible : il doit y avoir au moins un instructeur dans le groupe') }
      it { expect(response).to redirect_to(procedure_groupe_instructeur_path(procedure, gi_1_1)) }
    end
  end

  describe '#update_routing_criteria_name' do
    before do
      patch :update_routing_criteria_name,
        params: {
          procedure_id: procedure.id,
          procedure: { routing_criteria_name: 'new name !' }
        }
    end

    it { expect(procedure.reload.routing_criteria_name).to eq('new name !') }
  end
end
