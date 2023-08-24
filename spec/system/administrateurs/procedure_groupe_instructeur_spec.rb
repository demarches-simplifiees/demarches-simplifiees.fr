require 'system/administrateurs/procedure_spec_helper'

describe 'Manage procedure instructeurs', js: true do
  include ProcedureSpecHelper

  let(:administrateur) { create(:administrateur) }
  let!(:procedure) { create(:procedure) }
  let!(:administrateurs_procedure) { create(:administrateurs_procedure, administrateur: administrateur, procedure: procedure, manager: manager) }
  let(:manager) { false }
  before do
    login_as administrateur.user, scope: :user
  end

  context 'is accessible via card' do
    let(:manager) { false }

    scenario 'it works' do
      visit admin_procedure_path(procedure)
      find('#groupe-instructeurs').click
      expect(page).to have_css("h1", text: "Gestion des instructeurs")
    end
  end

  context 'as admin from manager' do
    let(:manager) { true }

    scenario 'cannot add instructeur' do
      visit admin_procedure_groupe_instructeurs_path(procedure)

      expect(page).to have_css("#instructeur_emails[disabled=\"disabled\"]")
    end
  end
end
