describe 'The routing', js: true do
  let(:password) { 'a very complicated password' }
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_service, :for_individual) }
  let(:administrateur) { create(:administrateur, procedures: [procedure]) }
  let(:scientifique_user) { create(:user, password: password) }
  let(:litteraire_user) { create(:user, password: password) }

  before do
    procedure.update(routing_enabled: true)
    procedure.defaut_groupe_instructeur.instructeurs << administrateur.instructeur
  end

  scenario 'works' do
    login_as administrateur.user, scope: :user

    visit admin_procedure_path(procedure.id)
    find('#groupe-instructeurs').click

    # rename routing criteria to spécialité
    fill_in 'Libellé du routage', with: 'spécialité'
    click_on 'Renommer'
    expect(page).to have_text('Le libellé est maintenant « spécialité ».')
    expect(page).to have_field('Libellé du routage', with: 'spécialité')

    # rename defaut groupe to littéraire
    click_on 'voir'
    fill_in 'Nom du groupe', with: 'littéraire'
    click_on 'Valider'
    expect(page).to have_text('Le nom est à présent « littéraire ».')
    expect(page).to have_field('Nom du groupe', with: 'littéraire')

    # add victor to littéraire groupe
    fill_in 'Emails', with: 'victor@inst.com'
    perform_enqueued_jobs { click_on 'Affecter' }
    expect(page).to have_text("L’instructeur victor@inst.com a été affecté au groupe « littéraire »")

    victor = User.find_by(email: 'victor@inst.com').instructeur

    # add superwoman to littéraire groupe
    fill_in 'Emails', with: 'superwoman@inst.com'
    perform_enqueued_jobs { click_on 'Affecter' }
    expect(page).to have_text("L’instructeur superwoman@inst.com a été affecté au groupe « littéraire »")

    superwoman = User.find_by(email: 'superwoman@inst.com').instructeur

    # add inactive groupe
    click_on 'Groupes d’instructeurs'
    fill_in 'Ajouter un groupe', with: 'non visible car inactif'
    click_on 'Ajouter le groupe'
    check "Groupe inactif"
    click_on 'Valider'

    # add scientifique groupe
    click_on 'Groupes d’instructeurs'
    fill_in 'Ajouter un groupe', with: 'scientifique'
    click_on 'Ajouter le groupe'
    expect(page).to have_text('Le groupe d’instructeurs « scientifique » a été créé.')

    # add marie to scientifique groupe
    fill_in 'Emails', with: 'marie@inst.com'
    perform_enqueued_jobs { click_on 'Affecter' }
    expect(page).to have_text("L’instructeur marie@inst.com a été affecté")

    marie = User.find_by(email: 'marie@inst.com').instructeur

    # add superwoman to scientifique groupe
    fill_in 'Emails', with: 'superwoman@inst.com'
    perform_enqueued_jobs { click_on 'Affecter' }
    expect(page).to have_text("L’instructeur superwoman@inst.com a été affecté")

    # publish
    publish_procedure(procedure)
    log_out

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
    find('.fr-search-bar .fr-btn').click
    expect(page).to have_text('0 dossier trouvé')

    fill_in 'q', with: litteraire_user.email
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

    click_on litteraire_user.dossiers.first.id.to_s
    click_on 'Modifier mon dossier'

    fill_in litteraire_user.dossiers.first.champs.first.libelle, with: 'some value'
    click_on 'Enregistrer les modifications du dossier'
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
    expect(find('.tabs')).to have_css('span.notifications')

    ## on the dossier itself
    click_on 'suivi'
    click_on litteraire_user.email
    expect(page).to have_current_path(instructeur_dossier_path(procedure, litteraire_user.dossiers.first))
    expect(page).to have_text('Annotations privées')
    expect(find('.tabs')).to have_css('span.notifications')
    log_out

    # the scientifiques instructeurs should not have a notification
    visit new_user_session_path
    sign_in_with marie.user.email, password

    expect(page).to have_current_path(instructeur_procedures_path)
    expect(find('.procedure-stats')).not_to have_css('span.notifications')
    log_out

    # the instructeurs who belong to scientifique AND litteraire groups manage scientifique and litterraire dossiers
    register_instructeur_and_log_in(superwoman.email)
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
    sign_in_with superwoman.user.email, password

    expect(page).to have_current_path(instructeur_procedures_path)
    expect(find('.procedure-stats')).to have_css('span.notifications')
  end

  def publish_procedure(procedure)
    click_on procedure.libelle
    find('#publish-procedure-link').click
    fill_in 'lien_site_web', with: 'http://some.website'
    click_on 'Publier'

    expect(page).to have_text('Démarche publiée')
  end

  def user_send_dossier(user, groupe)
    login_as user, scope: :user
    visit commencer_path(path: procedure.reload.path)
    click_on 'Commencer la démarche'

    choose 'Monsieur'
    fill_in 'individual_nom',    with: 'Nom'
    fill_in 'individual_prenom', with: 'Prenom'
    click_button('Continuer')

    select(groupe, from: 'dossier_groupe_instructeur_id')

    click_on 'Déposer le dossier'
    expect(page).to have_text('Merci')

    log_out
  end

  def user_update_group(user, new_group)
    login_as user, scope: :user
    visit dossiers_path
    click_on user.dossiers.first.id.to_s
    click_on "Modifier mon dossier"
    expect(page).to have_selector("option", text: "scientifique")
    expect(page).not_to have_selector("option", text: "Groupe inactif")

    select(new_group, from: 'dossier_groupe_instructeur_id')
    click_on "Enregistrer les modifications du dossier"
    expect(page).to have_text(new_group)

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
end
