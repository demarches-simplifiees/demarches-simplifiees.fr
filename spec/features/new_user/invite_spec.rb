require 'spec_helper'

feature 'Invitations' do
  let(:user) { create(:user) }
  let(:invited_user) { create(:user, email: 'user_invite@exemple.fr') }
  let(:procedure) { create(:procedure, :published, :with_type_de_champ) }
  let(:invite) { create(:invite_user, user: invited_user, dossier: dossier) }

  context 'when the dossier is a brouillon' do
    let!(:dossier) { create(:dossier, :for_individual, state: 'brouillon', user: user, procedure: procedure) }

    scenario 'on the form, a user can invite another user to collaborate on the dossier', js: true do
      log_in(user)
      navigate_to_brouillon(dossier)

      fill_in 'Libelle du champ', with: 'Some edited value'
      send_invite_to "user_invite@exemple.fr"

      expect(page).to have_current_path(modifier_dossier_path(dossier))
      expect(page).to have_text("Une invitation a été envoyée à user_invite@exemple.fr.")
      expect(page).to have_text("user_invite@exemple.fr")

      # Ensure unsaved edits to the form are not lost
      expect(page).to have_field('Libelle du champ', with: 'Some edited value')
    end

    scenario 'an invited user can see and edit the draft', js: true do
      visit users_dossiers_invite_path(invite)
      expect(page).to have_current_path(new_user_session_path)

      submit_login_form(invited_user)
      expect(page).to have_current_path(modifier_dossier_path(dossier))
      expect(page).to have_no_selector('.button.invite-user-action')

      fill_in 'Libelle du champ', with: 'Some edited value'
      click_button 'Enregistrer le brouillon'
      expect(page).to have_text('Votre brouillon a bien été sauvegardé')
      expect(page).to have_field('Libelle du champ', with: 'Some edited value')
    end

    scenario 'an invited user cannot submit the draft' do
      visit users_dossiers_invite_path(invite)
      expect(page).to have_current_path(new_user_session_path)

      submit_login_form(invited_user)
      expect(page).to have_current_path(modifier_dossier_path(dossier))

      expect(page).to have_button('Soumettre le dossier', disabled: true)
      expect(page).to have_selector('.invite-cannot-submit')
    end
  end

  context 'when the dossier is en_construction' do
    let!(:dossier) { create(:dossier, :for_individual, :en_construction, user: user, procedure: procedure) }

    scenario 'on dossier details, a user can invite another user to collaborate on the dossier', js: true do
      log_in(user)
      navigate_to_recapitulatif(dossier)

      legacy_send_invite_to "user_invite@exemple.fr"

      expect(page).to have_current_path(users_dossier_recapitulatif_path(dossier))
      expect(page).to have_text("Une invitation a été envoyée à user_invite@exemple.fr.")
      expect(page).to have_text("user_invite@exemple.fr")
    end

    scenario 'an invited user can see and edit the dossier', js: true do
      visit users_dossiers_invite_path(invite)
      expect(page).to have_current_path(new_user_session_path)

      submit_login_form(invited_user)
      expect(page).to have_current_path(users_dossiers_invite_path(invite))
      expect(page).to have_no_selector('.button.invite-user-action')
      expect(page).to have_text("Dossier nº #{dossier.id}")

      # We should be able to just click() the link, but Capybara detects that the
      # enclosing div would be clicked instead.
      expect(page).to have_link("MODIFIER", href: modifier_dossier_path(dossier))
      visit modifier_dossier_path(dossier)

      expect(page).to have_current_path(modifier_dossier_path(dossier))
      fill_in "Libelle du champ", with: "Some edited value"
      click_button "Enregistrer les modifications du dossier"

      expect(page).to have_current_path(users_dossiers_invite_path(invite))
      expect(page).to have_text("Some edited value")
    end
  end

  private

  def log_in(user)
    visit '/'
    click_on 'Connexion'
    submit_login_form(user)
    expect(page).to have_current_path(dossiers_path)
  end

  def submit_login_form(user)
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: user.password
    click_on 'Se connecter'
  end

  def navigate_to_brouillon(dossier)
    expect(page).to have_current_path(dossiers_path)
    click_on(dossier.id)
    expect(page).to have_current_path(modifier_dossier_path(dossier))
  end

  def navigate_to_recapitulatif(dossier)
    expect(page).to have_current_path(dossiers_path)
    click_on(dossier.id)
    expect(page).to have_current_path(users_dossier_recapitulatif_path(dossier))
  end

  def send_invite_to(invited_email)
    find('.button.invite-user-action').click()
    expect(page).to have_button("Envoyer une invitation", visible: true)

    fill_in 'invite_email', with: invited_email
    click_on "Envoyer une invitation"
  end

  def legacy_send_invite_to(invited_email)
    find('.dropdown-toggle', text: "Voir les personnes impliquées").click()
    expect(page).to have_button("Ajouter", visible: true)

    fill_in 'invite_email', with: invited_email

    page.accept_alert "Envoyer l'invitation ?" do
      click_on "Ajouter"
    end
  end
end
