require 'spec_helper'

feature 'Inviting an expert:' do
  include ActiveJob::TestHelper
  include ActionView::Helpers

  let(:instructeur) { create(:instructeur, password: 'démarches-simplifiées-pwd') }
  let(:expert) { create(:instructeur, password: expert_password) }
  let(:expert_password) { 'mot de passe d’expert' }
  let(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }
  let(:dossier) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure) }

  context 'as an Instructeur' do
    scenario 'I can invite an expert' do
      login_as instructeur.user, scope: :user
      visit instructeur_dossier_path(procedure, dossier)

      click_on 'Avis externes'
      expect(page).to have_current_path(avis_instructeur_dossier_path(procedure, dossier))

      fill_in 'avis_emails', with: 'expert1@exemple.fr, expert2@exemple.fr'
      fill_in 'avis_introduction', with: 'Bonjour, merci de me donner votre avis sur ce dossier.'
      page.select 'confidentiel', from: 'avis_confidentiel'

      perform_enqueued_jobs do
        click_on 'Demander un avis'
      end

      expect(page).to have_content('Une demande d\'avis a été envoyée')
      expect(page).to have_content('Avis des invités')
      within('.list-avis') do
        expect(page).to have_content('expert1@exemple.fr')
        expect(page).to have_content('expert2@exemple.fr')
        expect(page).to have_content('Bonjour, merci de me donner votre avis sur ce dossier.')
      end

      invitation_email = open_email('expert2@exemple.fr')
      avis = Avis.find_by(email: 'expert2@exemple.fr')
      sign_up_link = sign_up_instructeur_avis_path(avis.id, avis.email)
      expect(invitation_email.body).to include(sign_up_link)
    end

    context 'when experts submitted their answer' do
      let!(:answered_avis) { create(:avis, :with_answer, dossier: dossier, claimant: instructeur, email: expert.email) }

      scenario 'I can read the expert answer' do
        login_as instructeur.user, scope: :user
        visit instructeur_dossier_path(procedure, dossier)

        click_on 'Avis externes'

        expect(page).to have_content(expert.email)
        answered_avis.answer.split("\n").each do |answer_line|
          expect(page).to have_content(answer_line)
        end
      end
    end
  end

  context 'as an invited Expert' do
    let(:avis_email) { expert.email }
    let(:avis) { create(:avis, dossier: dossier, claimant: instructeur, email: avis_email, confidentiel: true) }

    context 'when I don’t already have an account' do
      let(:avis_email) { 'not-signed-up-expert@exemple.fr' }

      scenario 'I can sign up' do
        visit sign_up_instructeur_avis_path(avis.id, avis_email)

        expect(page).to have_field('Email', with: avis_email, disabled: true)
        fill_in 'Mot de passe', with: 'This is a very complicated password !'
        click_on 'Créer un compte'

        expect(page).to have_current_path(instructeur_avis_index_path)
        expect(page).to have_text('avis à donner 1')
      end
    end

    context 'when I already have an existing account' do
      let(:avis_email) { expert.email }

      scenario 'I can sign in' do
        visit sign_up_instructeur_avis_path(avis.id, avis_email)

        expect(page).to have_current_path(new_user_session_path)
        sign_in_with(expert.email, expert_password)

        expect(page).to have_current_path(instructeur_avis_index_path)
        expect(page).to have_text('avis à donner 1')
      end
    end

    scenario 'I can give an answer' do
      avis # create avis
      login_as expert.user, scope: :user

      visit instructeur_avis_index_path
      expect(page).to have_text('avis à donner 1')
      expect(page).to have_text('avis donnés 0')

      click_on avis.dossier.user.email

      within('.tabs') { click_on 'Avis' }
      expect(page).to have_text("Demandeur : #{instructeur.email}")
      expect(page).to have_text('Cet avis est confidentiel')

      fill_in 'avis_answer', with: 'Ma réponse d’expert : c’est un oui.'
      find('.piece-justificative input[type=file]').attach_file(Rails.root + 'spec/fixtures/files/RIB.pdf')
      click_on 'Envoyer votre avis'

      expect(page).to have_content('Votre réponse est enregistrée')
      expect(page).to have_content('Ma réponse d’expert : c’est un oui.')
      expect(page).to have_content('RIB.pdf')

      within('.new-header') { click_on 'Avis' }
      expect(page).to have_text('avis à donner 0')
      expect(page).to have_text('avis donné 1')
    end

    # TODO
    # scenario 'I can read other experts advices' do
    # end

    # scenario 'I can invite other experts' do
    # end
  end
end
