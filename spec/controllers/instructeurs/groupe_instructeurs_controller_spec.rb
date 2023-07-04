describe Instructeurs::GroupeInstructeursController, type: :controller do
  render_views

  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published) }
  let!(:gi_1_1) { procedure.defaut_groupe_instructeur }
  let!(:gi_1_2) { create(:groupe_instructeur, label: 'groupe instructeur 2', procedure: procedure) }

  let(:procedure2) { create(:procedure, :published) }
  let!(:gi_2_2) { create(:groupe_instructeur, label: 'groupe instructeur 2 2', procedure: procedure2) }

  before do
    gi_1_2.instructeurs << instructeur
    sign_in(instructeur.user)
  end

  describe '#index' do
    context 'of a procedure I own' do
      before do
        get :index, params: { procedure_id: procedure.id }
      end

      context 'when a procedure has multiple groups' do
        it { expect(response).to have_http_status(:ok) }
        it { expect(response.body).to include(gi_1_2.label) }
        it { expect(response.body).not_to include(gi_1_1.label) }
        it { expect(response.body).not_to include(gi_2_2.label) }
      end
    end
  end

  describe '#show' do
    context 'of a group I belong to' do
      before { get :show, params: { procedure_id: procedure.id, id: gi_1_2.id } }

      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe '#add_instructeur' do
    before do
      post :add_instructeur,
        params: {
          procedure_id: procedure.id,
          id: gi_1_2.id,
          instructeur: { email: new_instructeur_email }
        }
    end

    context 'of a new instructeur' do
      let(:new_instructeur_email) { 'new_instructeur@mail.com' }

      it { expect(gi_1_2.instructeurs.map(&:email)).to include(new_instructeur_email) }
      it { expect(flash.notice).to be_present }
      it { expect(response).to redirect_to(instructeur_groupe_path(procedure, gi_1_2)) }
    end

    context 'of an instructeur already in the group' do
      let(:new_instructeur_email) { instructeur.email }

      it { expect(flash.alert).to be_present }
      it { expect(response).to redirect_to(instructeur_groupe_path(procedure, gi_1_2)) }
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
end
