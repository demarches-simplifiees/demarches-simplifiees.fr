require 'system/administrateurs/procedure_spec_helper'

describe 'Administrateurs can manage administrateurs', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { administrateurs(:default_admin) }
  let(:procedure) { create(:procedure) }
  let(:manager) { false }
  before do
    procedure.administrateurs_procedures.update_all(manager:)
    login_as administrateur.user, scope: :user
  end

  scenario "card is clickable, and i can send invitation when i'm not a manager" do
    another_administrateur = create(:administrateur)
    visit admin_procedure_path(procedure)
    find('#administrateurs').click
    expect(page).to have_css("h1", text: "Administrateurs")

    fill_in('administrateur_email', with: another_administrateur.email)

    click_on 'Ajouter comme administrateur'
    within('.alert-success') do
      expect(page).to have_content(another_administrateur.email)
    end
  end

  context 'as admin flagged from manager' do
    let(:manager) { true }
    scenario 'the administrator from manager can not add another administrator' do
      administrateur.administrateurs_procedures.update_all(manager: true)
      visit admin_procedure_administrateurs_path(procedure)

      expect(page).to have_css("#administrateur_email[disabled=\"disabled\"]")
    end
  end
end
