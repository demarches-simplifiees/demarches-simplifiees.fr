# frozen_string_literal: true

describe Manager::GestionnairesController, type: :controller do
  let(:super_admin) { create(:super_admin) }
  let(:gestionnaire) { create(:gestionnaire) }

  before { sign_in super_admin }

  describe '#index' do
    render_views

    it 'searches admin by email' do
      get :index, params: { search: gestionnaire.email }
      expect(response).to have_http_status(:success)
    end
  end

  describe '#show' do
    render_views

    before do
      get :show, params: { id: gestionnaire.id }
    end

    it { expect(response.body).to include(gestionnaire.email) }
  end

  describe '#delete' do
    before { sign_in super_admin }

    subject { delete :delete, params: { id: gestionnaire.id } }

    it 'deletes the gestionnaire' do
      subject

      expect(Gestionnaire.find_by(id: gestionnaire.id)).to be_nil
    end
  end
end
