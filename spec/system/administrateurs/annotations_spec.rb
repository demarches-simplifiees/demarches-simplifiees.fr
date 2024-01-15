describe 'As an administrateur I can edit annotation', js: true do
  let(:administrateur) { procedure.administrateurs.first }
  let(:procedure) { create(:procedure) }

  before do
    login_as administrateur.user, scope: :user
    visit annotations_admin_procedure_path(procedure)
  end

  scenario "adding a new champ" do
    click_on 'Ajouter une annotation'

    select('Carte', from: 'Type de champ')
    # ensure UI update is ok
    check 'Cadastres'
  end
end
