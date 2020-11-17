describe SuperAdmins::PasswordsController, type: :controller do
  describe '#test_strength' do
    it 'calculate score' do
      password = "bonjour"
      @request.env["devise.mapping"] = Devise.mappings[:super_admin]

      get 'test_strength', xhr: true, params: { super_admin: { password: password } }

      expect(assigns(:score)).to be_present
    end
  end
end
