require 'spec_helper'

feature 'Signin up:' do
  scenario 'a new user can sign-up' do
    visit root_path
    click_on 'Connexion'
    click_on 'Créer un compte'

    sign_up_with 'testuser@exemple.fr'
    expect(page).to have_content "Nous vous avons envoyé un email contenant un lien d'activation"

    click_confirmation_link_for 'testuser@exemple.fr'
    expect(page).to have_content 'Votre compte a été activé'
    expect(page).to have_current_path dossiers_path
  end

  context 'when visiting a procedure' do
    let(:procedure) { create :simple_procedure }

    before do
      visit commencer_path(path: procedure.path)
    end

    scenario 'a new user can sign-up and fill the procedure' do
      expect(page).to have_current_path new_user_session_path
      click_on 'Créer un compte'

      sign_up_with 'testuser@exemple.fr'
      expect(page).to have_content "Nous vous avons envoyé un email contenant un lien d'activation"

      click_confirmation_link_for 'testuser@exemple.fr'
      expect(page).to have_content 'Votre compte a été activé'
      expect(page).to have_content procedure.libelle
    end
  end
end
