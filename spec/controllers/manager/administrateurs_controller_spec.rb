describe Manager::AdministrateursController, type: :controller do
  let(:administration) { create(:administration) }

  describe 'GET #new' do
    render_views
    before do
      sign_in administration
    end

    it 'displays form to create a new admin' do
      get :new
      expect(response).to be_success
    end
  end

  describe 'POST #create' do
    let(:email) { 'plop@plop.com' }
    let(:password) { 'démarches-simplifiées-pwd' }

    before do
      sign_in administration
    end

    subject { post :create, params: { administrateur: { email: email } } }

    context 'when email and password are correct' do
      it 'add new administrateur in database' do
        expect { subject }.to change(Administrateur, :count).by(1)
      end

      it 'alert new mail are send' do
        expect(AdministrationMailer).to receive(:new_admin_email).and_return(AdministrationMailer)
        expect(AdministrationMailer).to receive(:deliver_later)
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
    let!(:admin) { create(:administrateur) }

    before { sign_in administration }

    subject { delete :delete, params: { id: admin.id } }

    it 'deletes the admin' do
      subject

      expect(Administrateur.find_by(id: admin.id)).to be_nil
    end
  end
end
