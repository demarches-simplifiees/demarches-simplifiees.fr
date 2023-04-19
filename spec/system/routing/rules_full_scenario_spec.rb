describe 'The routing with rules', js: true do
  let(:password) { 'a very complicated password' }

  let(:procedure) do
    create(:procedure, :with_service, :for_individual, :with_zone).tap do |p|
      p.draft_revision.add_type_de_champ(
        type_champ: :text,
        libelle: 'un premier champ text'
      )
      p.draft_revision.add_type_de_champ(
        type_champ: :drop_down_list,
        libelle: 'Spécialité',
        options: { "drop_down_other" => "0", "drop_down_options" => ["", "littéraire", "scientifique"] }
      )
    end
  end
  let(:administrateur) { create(:administrateur, procedures: [procedure]) }
  let(:scientifique_user) { create(:user, password: password) }
  let(:litteraire_user) { create(:user, password: password) }

  before do
    Flipper.enable(:routing_rules, procedure)
    procedure.defaut_groupe_instructeur.instructeurs << administrateur.instructeur
  end

  scenario 'works' do
    login_as administrateur.user, scope: :user
    visit admin_procedure_path(procedure.id)
    find('#groupe-instructeurs').click

    # add littéraire groupe
    fill_in 'Ajouter un nom de groupe', with: 'littéraire'
    click_on 'Ajouter le groupe'
    expect(page).to have_text('Le groupe d’instructeurs « littéraire » a été créé et le routage a été activé.')

    # add victor to littéraire groupe
    fill_in 'Emails', with: 'victor@inst.com'
    perform_enqueued_jobs { click_on 'Affecter' }
    expect(page).to have_text("L’instructeur victor@inst.com a été affecté")

    victor = User.find_by(email: 'victor@inst.com').instructeur

    # add superwoman to littéraire groupe
    fill_in 'Emails', with: 'superwoman@inst.com'
    perform_enqueued_jobs { click_on 'Affecter' }
    expect(page).to have_text("L’instructeur superwoman@inst.com a été affecté")

    superwoman = User.find_by(email: 'superwoman@inst.com').instructeur

    # add inactive groupe
    click_on 'Groupes d’instructeurs'
    fill_in 'Ajouter un nom de groupe', with: 'non visible car inactif'
    click_on 'Ajouter le groupe'
    check "Groupe inactif"
    click_on 'Modifier'

    # add scientifique groupe
    click_on 'Groupes d’instructeurs'
    fill_in 'Ajouter un nom de groupe', with: 'scientifique'
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

    # add routing rules
    click_on 'Groupes d’instructeurs'

    h = procedure.groupe_instructeurs.index_by(&:label).transform_values(&:id)

    within(".gi-#{h['scientifique']}") do
      within('.target') { select('Spécialité') }
      within('.value') { select('scientifique') }
    end

    within(".gi-#{h['littéraire']}") do
      within('.target') { select('Spécialité') }
      within('.value') { select('littéraire') }
    end

    not_defauts = procedure.groupe_instructeurs.filter { |gi| ['littéraire', 'scientifique'].include?(gi.label) }
    not_defauts.each { |gi| wait_until { gi.reload.routing_rule.present? } }

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

    click_on litteraire_user.dossiers.first.id.to_s
    click_on 'Modifier mon dossier'

    fill_in litteraire_user.dossiers.first.champs_public.first.libelle, with: 'some value'
    wait_for_autosave(false)

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
    click_on user.dossiers.first.id.to_s
    click_on "Modifier mon dossier"

    choose(new_group)
    wait_for_autosave(false)

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
end
