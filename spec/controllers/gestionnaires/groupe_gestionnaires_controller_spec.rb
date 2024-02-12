describe Gestionnaires::GroupeGestionnairesController, type: :controller do
  let(:gestionnaire) { create(:gestionnaire) }

  describe "#index" do
    subject { get :index }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
      let!(:other_groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
      let!(:not_my_groupe_gestionnaire) { create(:groupe_gestionnaire) }
      before do
        sign_in(gestionnaire.user)
        subject
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:groupe_gestionnaires)).to include(groupe_gestionnaire) }
      it { expect(assigns(:groupe_gestionnaires)).to include(other_groupe_gestionnaire) }
      it { expect(assigns(:groupe_gestionnaires)).not_to include(not_my_groupe_gestionnaire) }
    end
  end
end
