# frozen_string_literal: true

describe Manager::ServicesController, type: :controller do
  let(:super_admin) { create(:super_admin) }
  before do
    sign_in super_admin
    @service = create(:service)
  end

  render_views

  describe 'GET #index' do
    it "should list services" do
      get :index
      expect(response.body).to include(@service.nom)
    end

    it "should search by nom" do
      get :index, params: { search: @service.nom.first(3) }
      expect(response.body).to include(@service.nom)
    end
  end

  describe "GET #show" do
    before do
      get :show, params: { id: @service.id }
    end

    it do
      expect(response.body).to include(@service.nom)
      expect(response.body).to include("75 rue du Louvre")
      expect(response.body).to have_link(href: "https://www.geoportail.gouv.fr/carte?c=2.34,48.87&z=17&permalink=yes")
    end
  end
end
