describe AdminsGroupManagers::AdminsGroupsController, type: :controller do
  let(:admins_group_manager) { create(:admins_group_manager) }

  describe "#index" do
    subject { get :index }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      let!(:admins_group) { create(:admins_group, admins_group_managers: [admins_group_manager]) }
      before do
        sign_in(admins_group_manager.user)
        subject
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:admins_groups)).to include(admins_group) }
    end
  end
end
