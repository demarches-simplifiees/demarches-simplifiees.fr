describe Manager::UsersController, type: :controller do
  let(:administration) { create(:administration) }

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
