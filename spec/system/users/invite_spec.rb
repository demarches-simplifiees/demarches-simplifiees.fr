require 'system/users/dossier_shared_examples.rb'

describe 'Invitations' do
  let(:owner) { create(:user) }
  let(:invited_user) { create(:user, email: 'user_invite@exemple.fr') }
  let(:procedure) { create(:simple_procedure) }
  let(:invite) { create(:invite, user: invited_user, dossier: dossier) }

  context 'when the dossier is a brouillon' do
    let!(:dossier) { create(:dossier, :with_individual, state: Dossier.states.fetch(:brouillon), user: owner, procedure: procedure) }

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

      scenario 'an invited user can register using the targeted_user_link sent in the invitation email thru the ' do
        log_in(owner)
        navigate_to_brouillon(dossier)

        fill_in 'Texte obligatoire', with: 'Some edited value'

        send_invite_to "user_invite@exemple.fr"

        expect {
          perform_enqueued_jobs
        }.to change { TargetedUserLink.count }.from(0).to(1)

        invitation_email = open_email("user_invite@exemple.fr")
        targeted_user_link = TargetedUserLink.last
        expect(invitation_email).to have_link(targeted_user_link_url(targeted_user_link))
        invitation_email.click_on targeted_user_link_url(targeted_user_link)
        expect(page).to have_current_path("/users/sign_up?user%5Bemail%5D=user_invite%40exemple.fr")
      end
    end

    context 'when inviting someone with an existing account' do
      let(:user) { create(:user) }

      scenario 'an invited user can sign in using the targeted_user_link link sent in the invitation email' do
        log_in(owner)
        navigate_to_brouillon(dossier)

        fill_in 'Texte obligatoire', with: 'Some edited value'
        send_invite_to user.email

        expect {
          perform_enqueued_jobs
        }.to change { TargetedUserLink.count }.from(0).to(1)

        invitation_email = open_email(user.email)
        targeted_user_link = TargetedUserLink.last
        expect(targeted_user_link.user.email).to eq(user.email)
        expect(invitation_email).to have_link(targeted_user_link_url(targeted_user_link))
        invitation_email.click_on targeted_user_link_url(targeted_user_link)
        expect(page).to have_current_path("/users/sign_in")
      end
    end

    context 'when visiting targeted_user_link having an invite without user, but signed with another account' do
      let(:invite) { create(:invite, user: nil, email: 'target@email.com') }
      let!(:targeted_user_link) { create(:targeted_user_link, target_context: 'invite', target_model: invite) }
      let!(:another_user) { create(:user) }

      scenario 'the connected user is alterted he is not using the expected account' do
        log_in(another_user)
        visit targeted_user_link_path(targeted_user_link)
        expect(page).to have_current_path(targeted_user_link_path(targeted_user_link))
        expect(page).to have_content("L'invitation est à destination de #{targeted_user_link.target_email}")
      end
    end

    context 'when visiting targeted_user_link having an invite with user, but signed with another account' do
      let(:invite) { create(:invite, user: create(:user)) }
      let!(:targeted_user_link) { create(:targeted_user_link, target_context: 'invite', target_model: invite, user: invite.user) }
      let!(:another_user) { create(:user) }

      scenario 'the connected user is alterted he is not using the expected account' do
        log_in(another_user)
        visit targeted_user_link_path(targeted_user_link)
        expect(page).to have_current_path(targeted_user_link_path(targeted_user_link))
        expect(page).to have_content("L'invitation est à destination de #{targeted_user_link.target_email}")
      end
    end

    scenario 'an invited user can see and edit the draft', js: true do
      navigate_to_invited_dossier(invite)
      expect(page).to have_current_path(brouillon_dossier_path(dossier))

      expect(page).to have_no_selector('.button.invite-user-action')

      fill_in 'Texte obligatoire', with: 'Some edited value'
      blur
      expect(page).to have_field('Texte obligatoire', with: 'Some edited value')
    end

    scenario 'an invited user cannot submit the draft' do
      navigate_to_invited_dossier(invite)
      expect(page).to have_current_path(brouillon_dossier_path(dossier))

      expect(page).to have_button('Déposer le dossier', disabled: true)
      expect(page).to have_selector('.invite-cannot-submit')
    end
  end

  context 'when the dossier is en_construction' do
    let!(:dossier) { create(:dossier, :with_individual, :en_construction, user: owner, procedure: procedure) }

    scenario 'on dossier details, the owner of a dossier can invite another user to collaborate on the dossier', js: true do
      log_in(owner)
      navigate_to_dossier(dossier)

      send_invite_to "user_invite@exemple.fr"

      expect(page).to have_current_path(dossier_path(dossier))
      expect(page).to have_text("Une invitation a été envoyée à user_invite@exemple.fr.")
      expect(page).to have_text("user_invite@exemple.fr")
    end

    context 'as an invited user', js: true do
      before do
        navigate_to_invited_dossier(invite)
        expect(page).to have_current_path(dossier_path(invite.dossier))
      end

      it_behaves_like 'the user can edit the submitted demande'
      it_behaves_like 'the user can send messages to the instructeur'
    end
  end

  describe 'recherche' do
    context "when user has one invited dossier" do
      let!(:dossier) { create(:dossier, :with_individual, :en_construction, user: owner, procedure: procedure) }
      let!(:invite) { create(:invite, user: invited_user, dossier: dossier) }
      before do
        navigate_to_invited_dossier(invite)
        visit dossiers_path
      end

      it "does not have access to search bar" do
        expect(page).not_to have_selector('#q')
      end
    end

    context "when user has multiple invited dossiers" do
      let(:dossier) { create(:dossier, :with_individual, :en_construction, user: owner, procedure: procedure) }
      let!(:dossier_2) { create(:dossier, :with_individual, :with_populated_champs, :en_construction, user: owner, procedure: procedure) }
      let!(:invite_2) { create(:invite, user: invited_user, dossier: dossier_2) }
      let!(:dossier_3) { create(:dossier, :with_individual, :en_construction, user: owner, procedure: procedure) }
      let!(:invite_3) { create(:invite, user: invited_user, dossier: dossier_3) }
      before do
        navigate_to_invited_dossier(invite)
        visit dossiers_path
        perform_enqueued_jobs(only: DossierIndexSearchTermsJob)
      end

      it "can search by id and it displays the dossier" do
        page.find_by_id('q').set(dossier.id)
        find('.fr-search-bar .fr-btn').click
        expect(current_path).to eq(dossiers_path)
        expect(page).to have_link(dossier.procedure.libelle)
      end

      it "can search something inside the dossier and it displays the dossier" do
        page.find_by_id('q').set(dossier_2.champs_public.first.value)
        find('.fr-search-bar .fr-btn').click
        expect(current_path).to eq(dossiers_path)
        expect(page).to have_link(dossier.procedure.libelle)
      end
    end
  end

  private

  def log_in(user)
    visit new_user_session_path
    sign_in_with(user.email, user.password)
    expect(page).to have_current_path(dossiers_path)
  end

  def navigate_to_brouillon(dossier)
    expect(page).to have_current_path(dossiers_path)
    click_on(dossier.procedure.libelle)
    expect(page).to have_current_path(brouillon_dossier_path(dossier))
  end

  def navigate_to_dossier(dossier)
    expect(page).to have_current_path(dossiers_path)
    click_on(dossier.procedure.libelle)
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
