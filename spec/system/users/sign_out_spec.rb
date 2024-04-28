# frozen_string_literal: true

describe 'Sign out' do
  context 'when a user is logged in' do
    let(:user) { create(:administrateur).user }

    before { login_as user, scope: :user }

    scenario 'he can sign out' do
      visit dossiers_path

      click_on 'Se déconnecter'

      expect(page).to have_current_path(root_path)
    end
  end
end
