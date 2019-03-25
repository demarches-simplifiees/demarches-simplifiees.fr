RSpec.shared_examples 'the user can edit the submitted demande' do
  scenario js: true do
    visit dossier_path(dossier)

    expect(page).to have_current_path(dossier_path(dossier))
    click_on 'Demande'

    expect(page).to have_current_path(demande_dossier_path(dossier))
    click_on 'Modifier le dossier'

    expect(page).to have_current_path(modifier_dossier_path(dossier))
    fill_in('Texte obligatoire', with: 'Nouveau texte')
    click_on 'Enregistrer les modifications du dossier'

    expect(page).to have_current_path(demande_dossier_path(dossier))
    expect(page).to have_content('Nouveau texte')
  end
end

RSpec.shared_examples 'the user can send messages to the instructeur' do
  let!(:commentaire) { create(:commentaire, dossier: dossier, email: 'instructeur@exemple.fr', body: 'Message envoyé à l’usager') }
  let(:message_body) { 'Message envoyé à l’instructeur' }

  scenario js: true do
    visit dossier_path(dossier)

    expect(page).to have_current_path(dossier_path(dossier))
    click_on 'Messagerie'

    expect(page).to have_current_path(messagerie_dossier_path(dossier))
    expect(page).to have_content(commentaire.body)

    fill_in 'commentaire_body', with: message_body
    click_on 'Envoyer le message'

    expect(page).to have_current_path(messagerie_dossier_path(dossier))
    expect(page).to have_content('Message envoyé')
    expect(page).to have_content(commentaire.body)
    expect(page).to have_content(message_body)
  end
end
