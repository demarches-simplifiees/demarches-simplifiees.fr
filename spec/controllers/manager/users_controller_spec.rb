describe Manager::UsersController, type: :controller do
  let(:administration) { create(:administration) }

  describe '#show' do
    render_views

    let(:administration) { create(:administration) }
    let(:user) { create(:user) }

    before do
      sign_in(administration)
      get :show, params: { id: user.id }
    end

    it { expect(response.body).to include(user.email) }
  end

  describe '#update' do
    let!(:user) { create(:user, email: 'ancien.email@domaine.fr') }

    before {
      sign_in administration
    }
    subject { patch :update, params: { id: user.id, user: { email: nouvel_email } } }

    describe 'with a valid email' do
      let(:nouvel_email) { 'nouvel.email@domaine.fr' }

      it 'updates the user email' do
        subject

        expect(User.find_by(id: user.id).email).to eq(nouvel_email)
      end
    end

    describe 'with an invalid email' do
      let(:nouvel_email) { 'plop' }

      it 'does not update the user email' do
        subject

        expect(User.find_by(id: user.id).email).not_to eq(nouvel_email)
        expect(flash[:error]).to match("« #{nouvel_email} » n'est pas une adresse valide.")
      end
    end
  end

  describe '#delete' do
    let!(:user) { create(:user) }

    before { sign_in administration }

    subject { delete :delete, params: { id: user.id } }

    it 'deletes the user' do
      subject

      expect(User.find_by(id: user.id)).to be_nil
    end
  end
end
