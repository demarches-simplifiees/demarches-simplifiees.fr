describe 'As an administrateur', js: true do
  let(:super_admin) { create(:super_admin) }
  let(:admin_email) { 'new_admin@gouv.fr' }
  let(:new_admin) { Administrateur.by_email(admin_email) }
  let(:weak_password) { '12345678' }
  let(:strong_password) { 'a new, long, and complicated password!' }

  before do
    body = "{\"hs\": \"agent.educpop.gouv.fr\" }"
    WebMock.stub_request(:get, /https:\/\/matrix.agent.tchap.gouv.fr\/_matrix\/identity\/api\/v1\/info\?address=(.*)&medium=email/)
      .to_return(body: body, status: 200)

    perform_enqueued_jobs do
      super_admin.invite_admin(admin_email)
    end
  end

  scenario 'I can register' do
    expect(new_admin.reload.user.active?).to be(false)

    confirmation_email = open_email(admin_email)
    token_params = confirmation_email.body.match(/token=[^"]+/)

    visit "users/activate?#{token_params}"
    fill_in :user_password, with: weak_password

    expect(page).to have_text('Mot de passe très vulnérable')
    expect(page).to have_button('Définir le mot de passe', disabled: true)

    fill_in :user_password, with: strong_password
    expect(page).to have_text('Mot de passe suffisamment fort et sécurisé')
    expect(page).to have_button('Définir le mot de passe', disabled: false)

    click_button 'Définir le mot de passe'

    expect(page).to have_content 'Mot de passe enregistré'

    expect(new_admin.reload.user.active?).to be(true)
  end
end
