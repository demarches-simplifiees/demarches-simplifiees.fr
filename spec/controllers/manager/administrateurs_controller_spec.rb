describe Manager::AdministrateursController, type: :controller do
  let(:administration) { create(:administration) }
  let(:administrateur) { create(:administrateur) }

  before do
    sign_in administration
  end

  describe '#show' do
    render_views

    before do
      get :show, params: { id: administrateur.id }
    end

    it { expect(response.body).to include(administrateur.email) }
  end

  describe 'GET #new' do
    render_views
    it 'displays form to create a new admin' do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    let(:email) { 'plop@plop.com' }
    let(:password) { 'démarches-simplifiées-pwd' }

    subject { post :create, params: { administrateur: { email: email } } }

    context 'when email and password are correct' do
      it 'add new administrateur in database' do
        expect { subject }.to change(Administrateur, :count).by(1)
      end

      it 'alert new mail are send' do
        expect(AdministrationMailer).to receive(:invite_admin).and_return(AdministrationMailer)
        expect(AdministrationMailer).to receive(:deliver_later)
        subject
      end
    end

    context 'when email or password are missing' do
      let(:email) { '' }

      it { expect { subject }.to change(Administrateur, :count).by(0) }
    end
  end

  describe '#delete' do
    subject { delete :delete, params: { id: administrateur.id } }

    it 'deletes the admin' do
      subject

      expect(Administrateur.find_by(id: administrateur.id)).to be_nil
    end
  end

  describe '#index' do
    render_views

    it 'searches admin by email' do
      get :index, params: { search: administrateur.email }
      expect(response).to have_http_status(:success)
    end
  end
end
