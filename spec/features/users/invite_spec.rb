require 'spec_helper'
require 'features/users/dossier_shared_examples.rb'

feature 'Invitations' do
  let(:owner) { create(:user) }
  let(:invited_user) { create(:user, email: 'user_invite@exemple.fr') }
  let(:procedure) { create(:simple_procedure) }
  let(:invite) { create(:invite, user: invited_user, dossier: dossier) }

  context 'when the dossier is a brouillon' do
    let!(:dossier) { create(:dossier, :for_individual, state: Dossier.states.fetch(:brouillon), user: owner, procedure: procedure) }

    scenario 'on the form, the owner of a dossier can invite another user to collaborate on the dossier', js: true do
      log_in(owner)
      navigate_to_brouillon(dossier)

      fill_in 'Texte obligatoire', with: 'Some edited value'
      send_invite_to "user_invite@exemple.fr"

      expect(page).to have_current_path(brouillon_dossier_path(dossier))
      expect(page).to have_text("Une invitation a été envoyée à user_invite@exemple.fr.")
      expect(page).to have_text("user_invite@exemple.fr")

      # Ensure unsaved edits to the form are not lost
      expect(page).to have_field('Texte obligatoire', with: 'Some edited value')
    end

    context 'when inviting someone without an existing account' do
      let(:invite) { create(:invite, dossier: dossier, user: nil) }
      let(:user_password) { 'l33tus3r' }

      scenario 'an invited user can register using the registration link sent in the invitation email' do
        # Click the invitation link
        visit invite_path(invite, params: { email: invite.email })
        expect(page).to have_current_path(new_user_registration_path, ignore_query: true)
        expect(page).to have_field('user_email', with: invite.email)

        # Create the account
        sign_up_with invite.email, user_password
        expect(page).to have_content('lien d’activation')

        # Confirm the account
        # (The user should be redirected to the dossier they was invited on)
        click_confirmation_link_for invite.email
        expect(page).to have_content('Votre compte a été activé')
        expect(page).to have_current_path(brouillon_dossier_path(dossier))
      end
    end

    scenario 'an invited user can see and edit the draft', js: true do
      navigate_to_invited_dossier(invite)
      expect(page).to have_current_path(brouillon_dossier_path(dossier))

      expect(page).to have_no_selector('.button.invite-user-action')

      fill_in 'Texte obligatoire', with: 'Some edited value'
      click_button 'Enregistrer le brouillon'
      expect(page).to have_text('Votre brouillon a bien été sauvegardé')
      expect(page).to have_field('Texte obligatoire', with: 'Some edited value')
    end

    scenario 'an invited user cannot submit the draft' do
      navigate_to_invited_dossier(invite)
      expect(page).to have_current_path(brouillon_dossier_path(dossier))

      expect(page).to have_button('Soumettre le dossier', disabled: true)
      expect(page).to have_selector('.invite-cannot-submit')
    end
  end

  context 'when the dossier is en_construction' do
    let!(:dossier) { create(:dossier, :for_individual, :en_construction, user: owner, procedure: procedure) }

    scenario 'on dossier details, the owner of a dossier can invite another user to collaborate on the dossier', js: true do
      log_in(owner)
      navigate_to_dossier(dossier)

      send_invite_to "user_invite@exemple.fr"

      expect(page).to have_current_path(dossier_path(dossier))
      expect(page).to have_text("Une invitation a été envoyée à user_invite@exemple.fr.")
      expect(page).to have_text("user_invite@exemple.fr")
    end

    context 'as an invited user' do
      before do
        navigate_to_invited_dossier(invite)
        expect(page).to have_current_path(dossier_path(invite.dossier))
      end

      it_behaves_like 'the user can edit the submitted demande'
      it_behaves_like 'the user can send messages to the instructeur'
    end
  end

  private

  def log_in(user)
    visit '/'
    click_on 'Connexion'
    sign_in_with(user.email, user.password)
    expect(page).to have_current_path(dossiers_path)
  end

  def navigate_to_brouillon(dossier)
    expect(page).to have_current_path(dossiers_path)
    click_on(dossier.id)
    expect(page).to have_current_path(brouillon_dossier_path(dossier))
  end

  def navigate_to_dossier(dossier)
    expect(page).to have_current_path(dossiers_path)
    click_on(dossier.id)
    expect(page).to have_current_path(dossier_path(dossier))
  end

  def navigate_to_invited_dossier(invite)
    visit invite_path(invite)
    expect(page).to have_current_path(new_user_session_path)
    sign_in_with(invited_user.email, invited_user.password)
  end

  def send_invite_to(invited_email)
    click_on "Inviter une personne à modifier ce dossier"
    expect(page).to have_button("Envoyer une invitation", visible: true)

    fill_in 'invite_email', with: invited_email
    click_on "Envoyer une invitation"
  end
end
