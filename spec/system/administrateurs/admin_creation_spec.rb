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

  scenario 'I can register', js: true do
    expect(new_admin.reload.user.active?).to be(false)

    confirmation_email = open_email(admin_email)
    token_params = confirmation_email.body.match(/token=[^"]+/)

    visit "admin/activate?#{token_params}"
    fill_in :administrateur_password, with: weak_password

    expect(page).to have_text('Mot de passe très vulnérable')
    expect(page).to have_button('Continuer', disabled: true)

    fill_in :administrateur_password, with: strong_password
    expect(page).to have_text('Mot de passe suffisamment fort et sécurisé')
    expect(page).to have_button('Continuer', disabled: false)

    click_button 'Continuer'

    expect(page).to have_content 'Mot de passe enregistré'

    expect(new_admin.reload.user.active?).to be(true)
  end
end
