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

  describe "#show" do
    subject { get :show, params: { id: child_groupe_gestionnaire.id } }
    let!(:groupe_gestionnaire_root) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
    let!(:child_groupe_gestionnaire) { create(:groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire_root, gestionnaires: [gestionnaire]) }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(gestionnaire.user)
        subject
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:groupe_gestionnaire)).to eq(child_groupe_gestionnaire) }
    end
  end

  describe "#edit" do
    subject { get :edit, params: { id: child_groupe_gestionnaire.id } }
    let!(:groupe_gestionnaire_root) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
    let!(:child_groupe_gestionnaire) { create(:groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire_root, gestionnaires: [gestionnaire]) }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(gestionnaire.user)
        subject
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:groupe_gestionnaire)).to eq(child_groupe_gestionnaire) }
    end
  end

  describe "#update" do
    subject { post :update, params: { id: child_groupe_gestionnaire.id, groupe_gestionnaire: { name: 'new child name' } } }
    let!(:groupe_gestionnaire_root) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
    let!(:child_groupe_gestionnaire) { create(:groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire_root, gestionnaires: [gestionnaire]) }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(gestionnaire.user)
        subject
      end

      it { expect(child_groupe_gestionnaire.reload.name).to eq('new child name') }
      it { expect(response).to redirect_to(gestionnaire_groupe_gestionnaire_path(child_groupe_gestionnaire)) }
    end
  end

  describe "#destroy" do
    subject { post :destroy, params: { id: child_groupe_gestionnaire.id } }
    let!(:groupe_gestionnaire_root) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
    let!(:child_groupe_gestionnaire) { create(:groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire_root, gestionnaires: [gestionnaire]) }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(gestionnaire.user)
        subject
      end

      it { expect(GroupeGestionnaire.all.count).to eq(1) }
      it { expect(response).to redirect_to(gestionnaire_groupe_gestionnaires_path) }
    end
  end
end
