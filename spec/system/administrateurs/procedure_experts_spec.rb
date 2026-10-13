# frozen_string_literal: true

describe 'Manage procedure experts', js: true do
  let(:administrateur) { administrateurs.default }
  let(:procedure) { procedures.individual }

  before do
    procedure.update!(allow_expert_review: true, experts_require_administrateur_invitation: true)
    login_as administrateur.user, scope: :user
  end

  scenario 'the submit button is enabled only while an email is selected' do
    visit admin_procedure_experts_path(procedure)

    expect(page).to have_button('Ajouter à la liste', disabled: true)

    select_combobox('Emails', 'expert@gouv.fr', custom_value: true)
    expect(page).to have_button('Ajouter à la liste', disabled: false)

    click_button 'Supprimer expert@gouv.fr'
    expect(page).to have_button('Ajouter à la liste', disabled: true)
  end
end
