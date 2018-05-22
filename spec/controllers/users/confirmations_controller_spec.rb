describe Users::ConfirmationsController, type: :controller do
  let(:email) { 'mail@beta.gouv.fr' }
  let(:user) do
    create(:user,
      email: email,
      password: 'a good password',
      confirmation_token: '123',
      confirmed_at: nil)
  end

  before { @request.env["devise.mapping"] = Devise.mappings[:user] }

  describe '#check_invite!' do
    let!(:invite) { create(:invite, email: email) }
    let!(:invite2) { create(:invite, email: email) }

    before { get :show, params: { confirmation_token: user.confirmation_token } }

    it 'the new user is connect at his two invite' do
      expect(User.last.invites.size).to eq(2)
    end
  end
end
