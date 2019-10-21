require 'spec_helper'

feature 'Instructing a dossier:' do
  include ActiveJob::TestHelper

  let(:password) { 'démarches-simplifiées-pwd' }
  let!(:instructeur) { create(:instructeur, password: password) }

  let!(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }
  let!(:dossier) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure) }

  context 'the instructeur is also a user' do
    scenario 'a instructeur can fill a dossier' do
      visit commencer_path(path: procedure.path)
      click_on 'J’ai déjà un compte'

      expect(page).to have_current_path new_user_session_path
      sign_in_with(instructeur.email, password, true)

      # connexion link erase user stored location
      # expect(page).to have_current_path(commencer_path(path: procedure.path))

      visit commencer_path(path: procedure.path)
      click_on 'Commencer la démarche'

      expect(page).to have_content('Identifier votre établissement')
      expect(page).to have_current_path(siret_dossier_path(procedure.reload.dossiers.last))
      expect(page).to have_content(procedure.libelle)
    end
  end

  scenario 'A instructeur can accept a dossier', :js do
    log_in(instructeur.email, password)

    expect(page).to have_current_path(instructeur_procedures_path)

    click_on procedure.libelle
    expect(page).to have_current_path(instructeur_procedure_path(procedure))

    click_on dossier.user.email
    expect(page).to have_current_path(instructeur_dossier_path(procedure, dossier))

    click_on 'En construction'
    accept_confirm do
      click_on 'Passer en instruction'
    end
    expect(page).to have_text('En instruction')

    dossier.reload
    expect(dossier.state).to eq(Dossier.states.fetch(:en_instruction))

    click_on 'En instruction'

    within('.state-button') do
      click_on 'Accepter'
    end

    within('.accept.motivation') do
      fill_in('dossier_motivation', with: 'a good reason')

      accept_confirm do
        click_on 'Valider la décision'
      end
    end

    expect(page).to have_text('Dossier traité avec succès.')
    expect(page).to have_link('Archiver le dossier')

    dossier.reload
    expect(dossier.state).to eq(Dossier.states.fetch(:accepte))
    expect(dossier.motivation).to eq('a good reason')
  end

  scenario 'A instructeur can follow/unfollow a dossier' do
    log_in(instructeur.email, password)

    click_on procedure.libelle
    test_statut_bar(a_suivre: 1, tous_les_dossiers: 1)
    dossier_present?(dossier.id, 'en construction')

    click_on 'Suivre le dossier'
    expect(page).to have_current_path(instructeur_procedure_path(procedure))
    test_statut_bar(suivi: 1, tous_les_dossiers: 1)
    expect(page).to have_text('Aucun dossier')

    click_on 'suivi'
    expect(page).to have_current_path(instructeur_procedure_path(procedure, statut: 'suivis'))
    dossier_present?(dossier.id, 'en construction')

    click_on 'Ne plus suivre'
    expect(page).to have_current_path(instructeur_procedure_path(procedure, statut: 'suivis'))
    test_statut_bar(a_suivre: 1, tous_les_dossiers: 1)
    expect(page).to have_text('Aucun dossier')
  end

  scenario 'A instructeur can see the personnes impliquées' do
    instructeur2 = FactoryBot.create(:instructeur, password: password)

    log_in(instructeur.email, password)

    click_on procedure.libelle
    click_on dossier.user.email

    click_on 'Avis externes'
    expect(page).to have_current_path(avis_instructeur_dossier_path(procedure, dossier))

    expert_email = 'expert@tps.com'
    ask_confidential_avis(expert_email, 'a good introduction')

    expert_email = instructeur2.email
    ask_confidential_avis(expert_email, 'a good introduction')

    click_on 'Personnes impliquées'
    expect(page).to have_text(expert_email)
    expect(page).to have_text(instructeur2.email)
  end

  scenario 'A instructeur can send a dossier to several instructeurs', js: true do
    instructeur_2 = FactoryBot.create(:instructeur)
    instructeur_3 = FactoryBot.create(:instructeur)
    procedure.defaut_groupe_instructeur.instructeurs << [instructeur_2, instructeur_3]

    send_dossier = double()
    expect(InstructeurMailer).to receive(:send_dossier).and_return(send_dossier).twice
    expect(send_dossier).to receive(:deliver_later).twice

    log_in(instructeur.email, password)

    click_on procedure.libelle
    click_on dossier.user.email

    click_on 'Personnes impliquées'

    first('.select2-container', minimum: 1).click
    find('li.select2-results__option[role="option"]', text: instructeur_2.email).click
    first('.select2-container', minimum: 1).click
    find('li.select2-results__option[role="option"]', text: instructeur_3.email).click

    click_on 'Envoyer'

    expect(page).to have_text("Dossier envoyé")
  end

  def log_in(email, password, check_email: true)
    visit '/'
    click_on 'Connexion'
    expect(page).to have_current_path(new_user_session_path)

    sign_in_with(email, password, check_email)

    expect(page).to have_current_path(instructeur_procedures_path)
  end

  def log_out
    click_on 'Se déconnecter'
  end

  def ask_confidential_avis(to, introduction)
    fill_in 'avis_emails', with: to
    fill_in 'avis_introduction', with: introduction
    select 'confidentiel', from: 'avis_confidentiel'
    click_on 'Demander un avis'
  end

  def test_mail(to, content)
    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to match([to])
    expect(mail.body.parts.map(&:to_s)).to all(include(content))
  end

  def test_statut_bar(a_suivre: 0, suivi: 0, traite: 0, tous_les_dossiers: 0, archive: 0)
    texts = [
      "à suivre #{a_suivre}",
      "suivi #{suivi}",
      "traité #{traite}",
      "tous les dossiers #{tous_les_dossiers}",
      "archivé #{archive}"
    ]

    texts.each { |text| expect(page).to have_text(text) }
  end

  def avis_sign_up(avis, email)
    visit sign_up_instructeur_avis_path(avis, email)
    fill_in 'instructeur_password', with: 'démarches-simplifiées-pwd'
    click_on 'Créer un compte'
    expect(page).to have_current_path(instructeur_avis_index_path)
  end

  def dossier_present?(id, statut)
    within(:css, '.dossiers-table') do
      expect(page).to have_text(id)
      expect(page).to have_text(statut)
    end
  end
end
