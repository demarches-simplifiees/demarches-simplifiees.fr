describe 'The routing with rules', js: true do
  let(:password) { 'a very complicated password' }

  let(:procedure) do
    create(:procedure, :with_service, :for_individual, :with_zone, types_de_champ_public: [
      { type: :text, libelle: 'un premier champ text' },
      { type: :drop_down_list, libelle: 'Spécialité', options: ["", "littéraire", "scientifique", "artistique"] }
    ])
  end
  let(:administrateur) { create(:administrateur, procedures: [procedure]) }
  let(:scientifique_user) { create(:user, password: password) }
  let(:litteraire_user) { create(:user, password: password) }
  let(:artistique_user) { create(:user, password: password) }

  before do
    procedure.defaut_groupe_instructeur.instructeurs << administrateur.instructeur
  end

  scenario 'Routage à partir d’un champ' do
    steps_to_routing_configuration

    choose('À partir d’un champ', allow_label_click: true)
    click_on 'Continuer'

    expect(page).to have_text('Routage à partir d’un champ')

    choose('Spécialité', allow_label_click: true)
    click_on 'Créer les groupes'

    expect(page).to have_text('Gestion des groupes')
    expect(page).to have_text('3 groupes')
    expect(page).not_to have_text('à configurer')

    click_on 'littéraire'
    expect(page).to have_select("groupe_instructeur[condition_form][rows][][targeted_champ]", selected: "Spécialité")
    expect(page).to have_select("groupe_instructeur[condition_form][rows][][value]", selected: "littéraire")

    click_on '3 groupes'
    click_on 'scientifique'

    expect(page).to have_select("groupe_instructeur[condition_form][rows][][targeted_champ]", selected: "Spécialité")
    expect(page).to have_select("groupe_instructeur[condition_form][rows][][value]", selected: "scientifique")
  end

  scenario 'Routage avancé' do
    steps_to_routing_configuration

    choose('Avancé', allow_label_click: true)
    click_on 'Continuer'

    expect(page).to have_text('Gestion des groupes')
    expect(page).to have_text('règle invalide')

    # update defaut groupe
    click_on 'défaut'
    expect(page).to have_text('Paramètres du groupe')
    fill_in 'Nom du groupe', with: 'littéraire'
    click_on 'Renommer'
    expect(page).to have_text('Le nom est à présent « littéraire ». ')

    # add victor to littéraire groupe
    fill_in 'Emails', with: 'victor@gouv.fr'
    perform_enqueued_jobs { click_on 'Affecter' }
    expect(page).to have_text("L’instructeur victor@gouv.fr a été affecté")

    victor = User.find_by(email: 'victor@gouv.fr').instructeur

    # add alain to littéraire groupe
    fill_in 'Emails', with: 'alain@gouv.fr'
    perform_enqueued_jobs { click_on 'Affecter' }
    expect(page).to have_text("L’instructeur alain@gouv.fr a été affecté")

    alain = User.find_by(email: 'alain@gouv.fr').instructeur

    # add inactive groupe
    click_on 'Ajout de groupes'
    fill_in 'Nouveau groupe', with: 'non visible car inactif'
    click_on 'Ajouter'
    expect(page).to have_text('Le groupe d’instructeurs « non visible car inactif » a été créé. ')
    check("Groupe inactif", allow_label_click: true)

    # # add scientifique groupe
    click_on '3 groupes'
    click_on 'défaut bis'
    fill_in 'Nom du groupe', with: 'scientifique'
    click_on 'Renommer'
    expect(page).to have_text('Le nom est à présent « scientifique ». ')

    # add marie to scientifique groupe
    fill_in 'Emails', with: 'marie@gouv.fr'
    perform_enqueued_jobs { click_on 'Affecter' }
    expect(page).to have_text("L’instructeur marie@gouv.fr a été affecté")

    marie = User.find_by(email: 'marie@gouv.fr').instructeur

    # add superwoman to scientifique groupe
    fill_in 'Emails', with: 'alain@gouv.fr'
    perform_enqueued_jobs { click_on 'Affecter' }
    expect(page).to have_text("L’instructeur alain@gouv.fr a été affecté")

    # add routing rules
    within('.target select') { select('Spécialité') }
    within('.value select') { select('scientifique') }

    click_on '3 groupes'

    click_on 'littéraire'

    within('.target select') { select('Spécialité') }
    within('.value select') { select('scientifique') }

    expect(page).to have_text('règle déjà attribuée à scientifique')

    within('.target select') { select('Spécialité') }
    within('.value select') { select('littéraire') }

    expect(page).not_to have_text('règle déjà attribuée à scientifique')

    procedure.groupe_instructeurs.where(closed: false).each { |gi| wait_until { gi.reload.routing_rule.present? } }

    # add a group without routing rules
    click_on 'Ajout de groupes'
    fill_in 'Nouveau groupe', with: 'artistique'
    click_on 'Ajouter'
    expect(page).to have_text('Le groupe d’instructeurs « artistique » a été créé. ')
    expect(procedure.groupe_instructeurs.count).to eq(4)

    # publish
    publish_procedure(procedure)
    log_out

    # 3 users fill a dossier in each group
    user_send_dossier(scientifique_user, 'scientifique')
    user_send_dossier(litteraire_user, 'littéraire')
    user_send_dossier(artistique_user, 'artistique')

    perform_enqueued_jobs(only: DossierIndexSearchTermsJob)

    # the litteraires instructeurs only manage the litteraires dossiers
    register_instructeur_and_log_in(victor.email)
    click_on procedure.libelle
    expect(page).to have_text(litteraire_user.email)
    expect(page).not_to have_text(scientifique_user.email)

    # the search only show litteraires dossiers
    fill_in 'q', with: scientifique_user.email
    find('.fr-search-bar .fr-btn').click
    expect(page).to have_text('0 dossier trouvé')

    # weird bug, capabary appends text instead of replaces it
    # see https://github.com/redux-form/redux-form/issues/686
    fill_in('q', with: litteraire_user.email, fill_options: { clear: :backspace })
    find('.fr-search-bar .fr-btn').click
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
    visit new_user_session_path
    sign_in_with litteraire_user.email, password

    click_on litteraire_user.dossiers.first.procedure.libelle
    click_on 'Modifier mon dossier'

    fill_in litteraire_user.dossiers.first.champs_public.first.libelle, with: 'some value'
    wait_for_autosave

    click_on 'Déposer les modifications'

    log_out

    # the litteraires instructeurs should have a notification
    visit new_user_session_path
    sign_in_with victor.user.email, password

    ## on the procedures list
    expect(page).to have_current_path(instructeur_procedures_path)
    expect(find('.procedure-stats')).to have_css('span.notifications')

    ## on the dossiers list
    click_on procedure.libelle
    expect(page).to have_current_path(instructeur_procedure_path(procedure))
    expect(find('.fr-tabs')).to have_css('span.notifications')

    ## on the dossier itself
    click_on 'suivi'
    click_on litteraire_user.email
    expect(page).to have_current_path(instructeur_dossier_path(procedure, litteraire_user.dossiers.first))
    expect(page).to have_text('Annotations privées')
    expect(find('.fr-tabs')).to have_css('span.notifications')
    log_out

    # the scientifiques instructeurs should not have a notification
    visit new_user_session_path
    sign_in_with marie.user.email, password

    expect(page).to have_current_path(instructeur_procedures_path)
    expect(find('.procedure-stats')).not_to have_css('span.notifications')
    log_out

    # the instructeurs who belong to scientifique AND litteraire groups manage scientifique and litteraire dossiers
    register_instructeur_and_log_in(alain.email)
    visit instructeur_procedure_path(procedure, params: { statut: 'tous' })
    expect(page).to have_text(litteraire_user.email)
    expect(page).to have_text(scientifique_user.email)

    # follow the dossier
    click_on scientifique_user.email
    click_on 'Suivre le dossier'

    visit instructeur_procedure_path(procedure, params: { statut: 'tous' })
    click_on litteraire_user.email
    click_on 'Suivre le dossier'
    log_out

    # scientifique_user updates its group
    user_update_group(scientifique_user, 'littéraire')

    # the instructeurs who belong to scientifique AND litteraire groups should have a notification
    visit new_user_session_path
    sign_in_with alain.user.email, password

    expect(page).to have_current_path(instructeur_procedures_path)
    expect(find('.procedure-stats')).to have_css('span.notifications')
  end

  def publish_procedure(procedure)
    click_on procedure.libelle
    find('#publish-procedure-link').click
    fill_in 'lien_site_web', with: 'http://some.website'
    within('form') { click_on 'Publier' }

    expect(page).to have_text('Votre démarche est désormais publiée !')
  end

  def user_send_dossier(user, groupe)
    login_as user, scope: :user
    visit commencer_path(path: procedure.reload.path)
    click_on 'Commencer la démarche'

    find('label', text: 'Monsieur').click
    fill_in('Prénom', with: 'prenom', visible: true)
    fill_in('Nom', with: 'Nom', visible: true)
    within "#identite-form" do
      click_button('Continuer')
    end

    # the old system should not be present
    expect(page).not_to have_selector("#dossier_groupe_instructeur_id")

    choose(groupe)
    wait_for_autosave

    click_on 'Déposer le dossier'
    expect(page).to have_text('Merci')

    log_out
  end

  def user_update_group(user, new_group)
    login_as user, scope: :user
    visit dossiers_path
    click_on user.dossiers.first.procedure.libelle
    click_on "Modifier mon dossier"

    choose(new_group)
    wait_for_autosave

    expect(page).to have_text(new_group)

    click_on 'Déposer les modifications'

    log_out
  end

  def register_instructeur_and_log_in(email)
    confirmation_email = emails_sent_to(email)
      .find { |m| m.subject == 'Activez votre compte instructeur' }
    token_params = confirmation_email.body.match(/token=[^"]+/)

    visit "users/activate?#{token_params}"
    fill_in :user_password, with: password
    click_button 'Définir le mot de passe'

    expect(page).to have_text('Mot de passe enregistré')
  end

  def steps_to_routing_configuration
    login_as administrateur.user, scope: :user
    visit admin_procedure_path(procedure.id)
    find('#groupe-instructeurs').click

    click_on 'Options'
    expect(page).to have_text('Options concernant l’instruction')
    click_on 'Configurer le routage'
    expect(page).to have_text('Choix du type de routage')
  end
end
