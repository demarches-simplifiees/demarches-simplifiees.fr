feature 'Inviting an expert:' do
  include ActiveJob::TestHelper
  include ActionView::Helpers

  context 'as an invited Expert' do
    let(:expert) { create(:expert) }
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }
    let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: procedure) }
    let(:dossier) { create(:dossier, :en_construction, :with_dossier_link, procedure: procedure) }
    let(:avis) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure, confidentiel: true) }

    context 'when I don’t already have an account' do
      scenario 'I can sign up' do
        visit sign_up_expert_avis_path(avis.dossier.procedure, avis, email: avis.expert.email)

        expect(page).to have_field('Email', with: avis.expert.email, disabled: true)
        fill_in 'Mot de passe', with: 'This is a very complicated password !'
        click_on 'Créer un compte'

        expect(page).to have_current_path(expert_all_avis_path)
        expect(page).to have_text('1 avis à donner')
      end
    end

    context 'when I already have an existing account' do
      before do
        avis.expert.user.update!(last_sign_in_at: Time.zone.now)
        avis.expert.user.reload
      end
      scenario 'I can sign in' do
        visit sign_up_expert_avis_path(avis.dossier.procedure, avis, email: avis.expert.email)

        expect(page).to have_current_path(new_user_session_path)
        login_as avis.expert.user, scope: :user
        sign_in_with(avis.expert.email, 'This is a very complicated password !')
        click_on 'Passer en expert'
        expect(page).to have_current_path(expert_all_avis_path)
        expect(page).to have_text('1 avis à donner')
      end
    end

    scenario 'I can give an answer' do
      avis # create avis
      login_as expert.user, scope: :user

      visit expert_all_avis_path
      expect(page).to have_text('1 avis à donner')
      expect(page).to have_text('0 avis donnés')

      click_on '1 avis à donner'
      click_on avis.dossier.user.email
      within('.tabs') { click_on 'Avis' }
      expect(page).to have_text("Demandeur : #{avis.claimant.email}")
      expect(page).to have_text('Cet avis est confidentiel')

      fill_in 'avis_answer', with: 'Ma réponse d’expert : c’est un oui.'
      find('.attachment input[name="avis[piece_justificative_file]"]').attach_file(Rails.root + 'spec/fixtures/files/RIB.pdf')
      click_on 'Envoyer votre avis'

      expect(page).to have_content('Votre réponse est enregistrée')
      expect(page).to have_content('Ma réponse d’expert : c’est un oui.')
      expect(page).to have_content('RIB.pdf')

      within('.breadcrumbs') { click_on 'Avis' }
      expect(page).to have_text('0 avis à donner')
      expect(page).to have_text('1 avis donné')
    end

    # scenario 'I can invite other experts' do
    # end
  end

  context 'when there are two experts' do
    let(:expert_1) { create(:expert) }
    let(:expert_2) { create(:expert) }
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }
    let(:experts_procedure_1) { create(:experts_procedure, expert: expert_1, procedure: procedure) }
    let(:experts_procedure_2) { create(:experts_procedure, expert: expert_2, procedure: procedure) }
    let(:dossier) { create(:dossier, :en_construction, :with_dossier_link, procedure: procedure) }
    let!(:avis_1) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure_1, confidentiel: true) }
    let!(:avis_2) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure_2, confidentiel: false) }

    scenario 'As a expert_1, I can read expert_2 advice because it is not confidential' do
      login_as expert_1.user, scope: :user

      visit expert_all_avis_path
      expect(page).to have_text('1 avis à donner')
      expect(page).to have_text('0 avis donnés')

      click_on '1 avis à donner'
      click_on avis_1.dossier.user.email
      within('.tabs') { click_on 'Avis' }
      expect(page).to have_text("Demandeur : #{avis_1.claimant.email}")
      expect(page).to have_text("Vous")
      expect(page).to have_text(avis_2.expert.email.to_s)
    end

    scenario 'As a expert_2, I cannot read expert_1 advice because it is confidential' do
      login_as expert_2.user, scope: :user

      visit expert_all_avis_path
      expect(page).to have_text('1 avis à donner')
      expect(page).to have_text('0 avis donnés')

      click_on '1 avis à donner'
      click_on avis_2.dossier.user.email
      within('.tabs') { click_on 'Avis' }
      expect(page).to have_text("Demandeur : #{avis_2.claimant.email}")
      expect(page).to have_text("Vous")
      expect(page).not_to have_text(avis_1.expert.email.to_s)
    end
  end
end
