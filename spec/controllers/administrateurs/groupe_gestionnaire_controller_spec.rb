describe Administrateurs::GroupeGestionnaireController, type: :controller do
  let(:admin) { create(:administrateur) }

  describe "#show" do
    subject { get :show }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      let(:gestionnaire) { create(:gestionnaire) }
      let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire], administrateurs: [admin]) }
      before do
        sign_in(admin.user)
        subject
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:groupe_gestionnaire)).to eq(groupe_gestionnaire) }
    end
  end

  describe "#gestionnaires" do
    subject { get :gestionnaires }
    let(:gestionnaire) { create(:gestionnaire) }
    let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire], administrateurs: [admin]) }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(admin.user)
        subject
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:groupe_gestionnaire)).to eq(groupe_gestionnaire) }
    end
  end

  describe "#administrateurs" do
    subject { get :administrateurs }
    let(:gestionnaire) { create(:gestionnaire) }
    let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire], administrateurs: [admin]) }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(admin.user)
        subject
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:groupe_gestionnaire)).to eq(groupe_gestionnaire) }
    end
  end
end
