describe Instructeurs::GroupeInstructeursController, type: :controller do
  render_views
  let(:administrateurs) { [create(:administrateur, user: instructeur.user)] }
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, administrateurs:) }
  let!(:gi_1_1) { procedure.defaut_groupe_instructeur }
  let!(:gi_1_2) { create(:groupe_instructeur, label: 'groupe instructeur 2', procedure: procedure) }

  let(:procedure2) { create(:procedure, :published) }
  let!(:gi_2_2) { create(:groupe_instructeur, label: 'groupe instructeur 2 2', procedure: procedure2) }

  before do
    gi_1_2.instructeurs << instructeur
    sign_in(instructeur.user)
  end

  describe "before_action: ensure_allowed!" do
    it "is present" do
      before_actions = Instructeurs::GroupeInstructeursController
        ._process_action_callbacks
        .filter { |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:ensure_allowed!)
    end
  end

  describe '#index (plus, ensure_allowed!)' do
    context 'when i own the procedure' do
      before { get :index, params: { procedure_id: procedure.id } }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when i am an instructeur of the procedure and instructeurs_self_management_enabled is true' do
      let(:procedure) { create(:procedure, :published, administrateurs: [create(:administrateur)], instructeurs_self_management_enabled: true) }
      before { get :index, params: { procedure_id: procedure.id } }

      context 'when a procedure has multiple groups' do
        it { expect(response).to have_http_status(:ok) }
        it { expect(response.body).to include(gi_1_2.label) }
        it { expect(response.body).not_to include(gi_1_1.label) }
        it { expect(response.body).not_to include(gi_2_2.label) }
      end
    end

    context 'when i am an instructor of the procedure, and instructeurs_self_management_enabled is false' do
      let(:procedure) { create(:procedure, :published, administrateurs: [create(:administrateur)], instructeurs_self_management_enabled: false) }
      before { get :index, params: { procedure_id: procedure.id } }

      it { expect(response).to have_http_status(:redirect) }
      it { expect(flash.alert).to eq("Vous n’avez pas le droit de gérer les instructeurs de cette démarche") }
    end

    context 'i am an instructor, not on the procedure' do
      let(:procedure) { create(:procedure, :published, administrateurs: [create(:administrateur)], instructeurs_self_management_enabled: true) }
      before do
        sign_in(create(:instructeur).user)
        get :index, params: { procedure_id: procedure.id }
      end

      it { expect(response).to have_http_status(:redirect) }
      it { expect(flash.alert).to eq("Vous n’avez pas accès à cette démarche") }
    end
  end

  describe '#show' do
    context 'of a group I belong to' do
      before { get :show, params: { procedure_id: procedure.id, id: gi_1_2.id } }

      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe '#add_instructeur' do
    subject do
      post :add_instructeur,
        params: {
          procedure_id: procedure.id,
          id: gi_1_2.id,
          instructeur: { email: new_instructeur_email }
        }
    end

    context 'of a new instructeur' do
      let(:new_instructeur_email) { 'new_instructeur@mail.com' }
      before { subject }

      it { expect(gi_1_2.instructeurs.map(&:email)).to include(new_instructeur_email) }
      it { expect(flash.notice).to be_present }
      it { expect(response).to redirect_to(instructeur_groupe_path(procedure, gi_1_2)) }
    end

    context 'of an instructeur already in the group' do
      let(:new_instructeur_email) { instructeur.email }
      before { subject }

      it { expect(flash.alert).to be_present }
      it { expect(response).to redirect_to(instructeur_groupe_path(procedure, gi_1_2)) }
    end

    context 'invalid email' do
      let(:new_instructeur_email) { 'invalid' }

      it { subject; expect(flash.alert).to include(new_instructeur_email) }
      it { expect { subject }.not_to enqueue_email }
    end
  end

  describe '#remove_instructeur' do
    let(:new_instructeur) { create(:instructeur) }
    let(:dossier) { create(:dossier) }

    before do
      gi_1_1.instructeurs << instructeur << new_instructeur
      gi_1_1.dossiers << dossier
      new_instructeur.followed_dossiers << dossier
    end

    def remove_instructeur(instructeur)
      delete :remove_instructeur,
        params: {
          procedure_id: procedure.id,
          id: gi_1_1.id,
          instructeur: { id: instructeur.id }
        }
    end

    context 'when there are many instructeurs' do
      before { remove_instructeur(new_instructeur) }

      it { expect(gi_1_1.instructeurs).to include(instructeur) }
      it { expect(gi_1_1.reload.instructeurs.count).to eq(1) }
      it { expect(new_instructeur.reload.follows.count).to eq(0) }
      it { expect(response).to redirect_to(instructeur_groupe_path(procedure, gi_1_1)) }
    end

    context 'when there is only one instructeur' do
      before do
        remove_instructeur(new_instructeur)
        remove_instructeur(instructeur)
      end

      it { expect(gi_1_1.instructeurs).to include(instructeur) }
      it { expect(gi_1_1.instructeurs.count).to eq(1) }
      it { expect(flash.alert).to eq('Suppression impossible : il doit y avoir au moins un instructeur dans le groupe') }
      it { expect(response).to redirect_to(instructeur_groupe_path(procedure, gi_1_1)) }
    end
  end

  describe '#add_signature' do
    let(:signature) { fixture_file_upload('spec/fixtures/files/black.png', 'image/png') }

    before do
      post :add_signature,
        params: {
          procedure_id: procedure.id,
          id: gi_1_2.id,
          groupe_instructeur: {
            signature: signature
          }
        }
    end

    it { expect(response).to redirect_to(instructeur_groupe_path(procedure, gi_1_2)) }
    it { expect(gi_1_2.reload.signature).to be_attached }
  end
end
