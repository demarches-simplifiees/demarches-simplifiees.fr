# frozen_string_literal: true

describe 'As an administateur i can setup a DossierSubmittedMessage' do
  let(:procedure) { create(:procedure, :for_individual, administrateurs: [administrateur], instructeurs: [create(:instructeur)]) }
  let(:administrateur) { create(:administrateur, user: create(:user)) }
  before { login_as administrateur.user, scope: :user }
  scenario 'Dossier submitted message' do
    visit edit_admin_procedure_dossier_submitted_message_path(procedure)
    page.execute_script("document.querySelector('[data-tiptap-target=\"input\"]').type = 'text'")
    fill_in 'dossier_submitted_message[tiptap_body]', with: '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"ok"}]}]}'
    click_on 'Enregistrer'
    expect(page).to have_content("Les informations de fin de dépot ont bien été sauvegardées.")
  end
end
