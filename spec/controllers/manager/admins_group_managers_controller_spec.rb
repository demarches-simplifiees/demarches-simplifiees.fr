describe Manager::AdminsGroupManagersController, type: :controller do
  let(:super_admin) { create(:super_admin) }
  let(:admins_group_manager) { create(:admins_group_manager) }

  before { sign_in super_admin }

  describe '#index' do
    render_views

    it 'searches admin by email' do
      get :index, params: { search: admins_group_manager.email }
      expect(response).to have_http_status(:success)
    end
  end

  describe '#show' do
    render_views

    before do
      get :show, params: { id: admins_group_manager.id }
    end

    it { expect(response.body).to include(admins_group_manager.email) }
  end
end
