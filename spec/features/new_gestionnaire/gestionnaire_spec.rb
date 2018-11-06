require 'spec_helper'

feature 'The gestionnaire part' do
  include ActiveJob::TestHelper

  let(:password) { 'secret_password' }
  let!(:gestionnaire) { create(:gestionnaire, password: password) }

  let!(:procedure) { create(:procedure, :published, gestionnaires: [gestionnaire]) }
  let!(:dossier) { create(:dossier, state: Dossier.states.fetch(:en_construction), procedure: procedure) }

  scenario 'A gestionnaire can accept a dossier', :js do
    log_in(gestionnaire.email, password)

    expect(page).to have_current_path(gestionnaire_procedures_path)

    click_on procedure.libelle
    expect(page).to have_current_path(gestionnaire_procedure_path(procedure))

    click_on dossier.user.email
    expect(page).to have_current_path(gestionnaire_dossier_path(procedure, dossier))

    click_on 'En construction'
    accept_confirm do
      click_on 'Passer en instruction'
    end
    expect(page).to have_text('En instruction')

    dossier.reload
    expect(dossier.state).to eq(Dossier.states.fetch(:en_instruction))

    click_on 'En instruction'

    within('.dropdown-items') do
      click_on 'Accepter'
    end

    within('.accept.motivation') do
      fill_in('dossier_motivation', with: 'a good reason')

      accept_confirm do
        click_on 'Valider la décision'
      end
    end

    expect(page).to have_text('Dossier traité avec succès.')

    dossier.reload
    expect(dossier.state).to eq(Dossier.states.fetch(:accepte))
    expect(dossier.motivation).to eq('a good reason')
  end

  scenario 'A gestionnaire can follow/unfollow a dossier' do
    log_in(gestionnaire.email, password)

    click_on procedure.libelle
    test_statut_bar(a_suivre: 1, tous_les_dossiers: 1)
    dossier_present?(dossier.id, 'en construction')

    click_on 'Suivre le dossier'
    expect(page).to have_current_path(gestionnaire_procedure_path(procedure))
    test_statut_bar(suivi: 1, tous_les_dossiers: 1)
    expect(page).to have_text('Aucun dossier')

    click_on 'suivi'
    expect(page).to have_current_path(gestionnaire_procedure_path(procedure, statut: 'suivis'))
    dossier_present?(dossier.id, 'en construction')

    click_on 'Ne plus suivre'
    expect(page).to have_current_path(gestionnaire_procedure_path(procedure, statut: 'suivis'))
    test_statut_bar(a_suivre: 1, tous_les_dossiers: 1)
    expect(page).to have_text('Aucun dossier')
  end

  scenario 'A gestionnaire can use avis' do
    log_in(gestionnaire.email, password)

    click_on procedure.libelle
    click_on dossier.user.email

    click_on 'Avis externes'
    expect(page).to have_current_path(avis_gestionnaire_dossier_path(procedure, dossier))

    expert_email = 'expert@tps.com'

    perform_enqueued_jobs do
      ask_confidential_avis(expert_email, 'a good introduction')
    end

    log_out

    avis = dossier.avis.first
    test_mail(expert_email, sign_up_gestionnaire_avis_path(avis, expert_email))

    avis_sign_up(avis, expert_email, 'a good password')

    expect(page).to have_current_path(gestionnaire_avis_index_path)
    expect(page).to have_text('avis à donner 1')
    expect(page).to have_text('avis donnés 0')

    click_on dossier.user.email
    expect(page).to have_current_path(gestionnaire_avis_path(dossier.avis.first))

    within(:css, '.tabs') do
      click_on 'Avis'
    end
    expect(page).to have_current_path(instruction_gestionnaire_avis_path(dossier.avis.first))

    within(:css, '.give-avis') do
      expect(page).to have_text("Demandeur : #{gestionnaire.email}")
      expect(page).to have_text('a good introduction')
      expect(page).to have_text('Cet avis est confidentiel')
      fill_in 'avis_answer', with: 'a great answer'
      click_on 'Envoyer votre avis'
    end

    log_out

    log_in(gestionnaire.email, password)

    click_on procedure.libelle
    click_on dossier.user.email
    click_on 'Avis externes'

    expect(page).to have_text('a great answer')
  end

  scenario 'A gestionnaire can see the personnes impliquées' do
    gestionnaire2 = FactoryBot.create(:gestionnaire, password: password)

    log_in(gestionnaire.email, password)

    click_on procedure.libelle
    click_on dossier.user.email

    click_on 'Avis externes'
    expect(page).to have_current_path(avis_gestionnaire_dossier_path(procedure, dossier))

    expert_email = 'expert@tps.com'
    ask_confidential_avis(expert_email, 'a good introduction')

    expert_email = gestionnaire2.email
    ask_confidential_avis(expert_email, 'a good introduction')

    click_on 'Personnes impliquées'
    expect(page).to have_text(expert_email)
    expect(page).to have_text(gestionnaire2.email)
  end

  scenario 'A gestionnaire can send a dossier to several instructeurs', js: true do
    instructeur_2 = FactoryBot.create(:gestionnaire)
    instructeur_3 = FactoryBot.create(:gestionnaire)
    procedure.gestionnaires << [instructeur_2, instructeur_3]

    send_dossier = double()
    expect(GestionnaireMailer).to receive(:send_dossier).and_return(send_dossier).twice
    expect(send_dossier).to receive(:deliver_later).twice

    log_in(gestionnaire.email, password)

    click_on procedure.libelle
    click_on dossier.user.email

    click_on 'Personnes impliquées'

    first('.select2-container', minimum: 1).click
    find('li.select2-results__option[role="treeitem"]', text: instructeur_2.email).click
    first('.select2-container', minimum: 1).click
    find('li.select2-results__option[role="treeitem"]', text: instructeur_3.email).click

    click_on 'Envoyer'

    expect(page).to have_text("Dossier envoyé")
  end

  def log_in(email, password)
    visit '/'
    click_on 'Connexion'
    expect(page).to have_current_path(new_user_session_path)

    fill_in 'user_email', with: email
    fill_in 'user_password', with: password
    click_on 'Se connecter'
    expect(page).to have_current_path(gestionnaire_procedures_path)
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
    mail = ActionMailer::Base.deliveries.first
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

  def avis_sign_up(avis, email, password)
    visit sign_up_gestionnaire_avis_path(avis, email)
    fill_in 'gestionnaire_password', with: 'a good password'
    click_on 'Créer un compte'
    expect(page).to have_current_path(gestionnaire_avis_index_path)
  end

  def dossier_present?(id, statut)
    within(:css, '.dossiers-table') do
      expect(page).to have_text(id)
      expect(page).to have_text(statut)
    end
  end
end
