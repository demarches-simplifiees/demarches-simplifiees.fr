describe 'Dossier details:' do
  let(:user) { create(:user) }
  let(:dossier) { create(:dossier, :en_construction, user: user) }

  before do
    Flipflop::FeatureSet.current.test!.switch!(:new_dossier_details, true)
  end

  scenario 'the user can see the details of their dossier' do
    visit_dossier dossier

    expect(page).to have_current_path(dossier_path(dossier))
    expect(page).to have_content(dossier.id)
  end

  private

  def visit_dossier(dossier)
    visit dossier_path(dossier)

    expect(page).to have_current_path(new_user_session_path)
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: user.password
    click_on 'Se connecter'

    expect(page).to have_current_path(dossier_path(dossier))
  end
end
