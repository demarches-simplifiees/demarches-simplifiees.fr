describe Manager::AdministrateursController, type: :controller do
  let(:administration){ create(:administration) }

  describe 'POST #create' do
    let(:email) { 'plop@plop.com' }
    let(:password) { 'password' }

    before do
      sign_in administration
    end

    subject { post :create, administrateur: { email: email } }

    context 'when email and password are correct' do
      it 'add new administrateur in database' do
        expect { subject }.to change(Administrateur, :count).by(1)
      end

      it 'alert new mail are send' do
        expect(AdministrationMailer).to receive(:new_admin_email).and_return(AdministrationMailer)
        expect(AdministrationMailer).to receive(:deliver_now!)
        expect(AdministrationMailer).to receive(:invite_admin).and_return(AdministrationMailer)
        expect(AdministrationMailer).to receive(:deliver_now!)
        subject
      end
    end

    context 'when email or password are missing' do
      let(:email) { '' }

      it { expect { subject }.to change(Administrateur, :count).by(0) }
    end
  end
end
