describe 'Dossier details:' do
  let(:user) { create(:user) }
  let(:simple_procedure) do
    tdcs = [create(:type_de_champ, libelle: 'texte obligatoire')]
    create(:procedure, :published, :for_individual, types_de_champ: tdcs)
  end
  let(:dossier) { create(:dossier, :en_construction, :for_individual, user: user, procedure: simple_procedure) }

  before do
    Flipflop::FeatureSet.current.test!.switch!(:new_dossier_details, true)
  end

  scenario 'the user can see the summary of the dossier status' do
    visit_dossier dossier

    expect(page).to have_current_path(dossier_path(dossier))
    expect(page).to have_content(dossier.id)
    expect(page).to have_selector('.status-explanation')
  end

  scenario 'the user can see and edit dossier before instruction' do
    visit_dossier dossier
    click_on 'Demande'

    expect(page).to have_current_path(demande_dossier_path(dossier))
    click_on 'Modifier le dossier'

    expect(page).to have_current_path(brouillon_dossier_path(dossier))
    fill_in('texte obligatoire', with: 'Nouveau texte')
    click_on 'Enregistrer les modifications du dossier'

    expect(page).to have_current_path(demande_dossier_path(dossier))
    expect(page).to have_content('Nouveau texte')
  end

  context 'with messages' do
    let!(:commentaire) { create(:commentaire, dossier: dossier, email: 'instructeur@exemple.fr', body: 'Message envoyé à l’usager') }
    let(:message_body) { 'Message envoyé à l’instructeur' }

    scenario 'the user can send a message' do
      visit_dossier dossier
      click_on 'Messagerie'

      expect(page).to have_current_path(messagerie_dossier_path(dossier))
      expect(page).to have_content(commentaire.body)

      fill_in 'commentaire_body', with: message_body
      click_on 'Envoyer'

      expect(page).to have_current_path(messagerie_dossier_path(dossier))
      expect(page).to have_content('Message envoyé')
      expect(page).to have_content(commentaire.body)
      expect(page).to have_content(message_body)
    end
  end

  private

  def visit_dossier(dossier)
    visit dossier_path(dossier)

    expect(page).to have_current_path(new_user_session_path)
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: user.password
    click_on 'Se connecter'

    expect(page).to have_current_path(dossier_path(dossier))
  end
end
