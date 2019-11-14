require 'spec_helper'

feature 'The routing', js: true do
  let(:password) { 'a very complicated password' }
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_service, :for_individual) }
  let(:administrateur) { create(:administrateur, procedures: [procedure]) }
  let(:scientifique_user) { create(:user, password: password) }
  let(:litteraire_user) { create(:user, password: password) }

  before do
    procedure.defaut_groupe_instructeur.instructeurs << administrateur.instructeur
    Flipper.enable_actor(:administrateur_routage, administrateur.user)
  end

  scenario 'works' do
    login_as administrateur.user, scope: :user

    visit admin_procedure_path(procedure.id)
    click_on "Groupe d'instructeurs"

    # rename routing criteria to spécialité
    fill_in 'procedure_routing_criteria_name', with: 'spécialité'
    click_on 'Renommer'
    expect(procedure.reload.routing_criteria_name).to eq('spécialité')

    # rename defaut groupe to littéraire
    click_on 'voir'
    expect(page).to have_css('#groupe_instructeur_label')
    2.times { find(:css, "#groupe_instructeur_label").set("littéraire") }
    click_on 'Renommer'

    expect(procedure.defaut_groupe_instructeur.reload.label).to eq('littéraire')

    # add victor to littéraire groupe
    try_twice { find('input.select2-search__field').send_keys('victor@inst.com', :enter) }

    perform_enqueued_jobs { click_on 'Affecter' }
    victor = User.find_by(email: 'victor@inst.com').instructeur

    click_on "Groupes d’instructeurs"

    # add scientifique groupe
    fill_in 'groupe_instructeur_label', with: 'scientifique'
    click_on 'Ajouter le groupe'

    # add marie to scientifique groupe
    try_twice { find('input.select2-search__field').send_keys('marie@inst.com', :enter) }
    perform_enqueued_jobs { click_on 'Affecter' }
    marie = User.find_by(email: 'marie@inst.com').instructeur

    # publish
    publish_procedure(procedure)
    log_out(old_layout: true)

    # 2 users fill a dossier in each group
    user_send_dossier(scientifique_user, 'scientifique')
    user_send_dossier(litteraire_user, 'littéraire')

    # the litteraires instructeurs only manage the litteraires dossiers
    register_instructeur_and_log_in(victor.email)
    click_on procedure.libelle
    expect(page).to have_text(litteraire_user.email)
    expect(page).not_to have_text(scientifique_user.email)

    # the search only show litteraires dossiers
    fill_in 'q', with: scientifique_user.email
    click_on 'Rechercher'
    expect(page).to have_text('0 dossier trouvé')

    fill_in 'q', with: litteraire_user.email
    click_on 'Rechercher'
    expect(page).to have_text('1 dossier trouvé')

    ## and the result is clickable
    click_on litteraire_user.email
    expect(page).to have_current_path(instructeur_dossier_path(procedure, litteraire_user.dossiers.first))

    # follow the dossier
    click_on 'Suivre le dossier'

    log_out

    # the scientifiques instructeurs only manage the scientifiques dossiers
    register_instructeur_and_log_in(marie.email)
    click_on procedure.libelle
    expect(page).not_to have_text(litteraire_user.email)
    expect(page).to have_text(scientifique_user.email)

    # follow the dossier
    click_on scientifique_user.email
    click_on 'Suivre le dossier'

    log_out

    # litteraire_user change its dossier
    visit root_path
    click_on 'Connexion'
    sign_in_with litteraire_user.email, password

    click_on litteraire_user.dossiers.first.id
    click_on 'Modifier mon dossier'

    fill_in 'dossier_champs_attributes_0_value', with: 'some value'
    click_on 'Enregistrer les modifications du dossier'
    log_out

    # the litteraires instructeurs should have a notification
    visit root_path
    click_on 'Connexion'
    sign_in_with victor.user.email, password

    ## on the procedures list
    visit instructeur_procedures_path
    expect(page).to have_css("span.notifications")

    ## on the dossiers list
    click_on procedure.libelle
    expect(page).to have_css("span.notifications")

    ## on the dossier it self
    click_on 'suivi'
    click_on litteraire_user.email
    expect(page).to have_css("span.notifications")

    log_out

    # the scientifiques instructeurs should not have a notification
    login_as marie.user, scope: :user
    visit instructeur_procedures_path
    expect(page).not_to have_css("span.notifications")
    log_out
  end

  def publish_procedure(procedure)
    click_on procedure.libelle
    find('#publish-procedure').click
    within '#publish-modal' do
      fill_in 'lien_site_web', with: 'http://some.website'
      click_on 'publish'
    end

    expect(page).to have_text('Démarche publiée')
  end

  def user_send_dossier(user, groupe)
    login_as user, scope: :user
    visit commencer_path(path: procedure.reload.path)
    click_on 'Commencer la démarche'

    fill_in 'individual_nom',    with: 'Nom'
    fill_in 'individual_prenom', with: 'Prenom'
    click_button('Continuer')

    select(groupe, from: 'dossier_groupe_instructeur_id')

    click_on 'Déposer le dossier'

    log_out
  end

  def register_instructeur_and_log_in(email)
    confirmation_email = emails_sent_to(email)
      .filter { |m| m.subject == 'Activez votre compte instructeur' }
      .first
    token_params = confirmation_email.body.match(/token=[^"]+/)

    visit "users/activate?#{token_params}"
    fill_in :user_password, with: password

    click_button 'Définir le mot de passe'

    expect(page).to have_content 'Mot de passe enregistré'
  end

  def log_out(old_layout: false)
    if old_layout
      expect(page).to have_content('Se déconnecter')
      click_on 'Se déconnecter'
    else
      try_twice do
        expect(page).to have_css('[title="Mon compte"]')
        find('[title="Mon compte"]').click
        expect(page).to have_content('Se déconnecter')
        click_on 'Se déconnecter'
      end
    end
  end

  def try_twice
    begin
      yield
    rescue Selenium::WebDriver::Error::ElementNotInteractableError, Capybara::ElementNotFound
      yield
    end
  end
end
