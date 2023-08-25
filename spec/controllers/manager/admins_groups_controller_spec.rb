describe Manager::AdminsGroupsController, type: :controller do
  let(:super_admin) { create(:super_admin) }
  let(:admins_group) { create(:admins_group) }

  before { sign_in super_admin }

  describe '#index' do
    render_views

    before do
      admins_group
      get :index
    end

    it { expect(response.body).to include(admins_group.name) }
  end

  describe '#show' do
    render_views

    before do
      get :show, params: { id: admins_group.id }
    end

    it { expect(response.body).to include(admins_group.name) }
  end
end
