require 'spec_helper'

feature 'procedure locked' do
  let(:administrateur) { create(:administrateur) }
  let(:published) { false }
  let(:procedure) { create(:procedure, administrateur: administrateur, published: published) }

  before do
    login_as administrateur, scope: :administrateur
    visit admin_procedure_path(procedure)
  end

  context 'when procedure is not published' do
    scenario 'info label is not present' do
      expect(page).not_to have_content('Cette procédure a été publiée, certains éléments ne peuvent plus être modifiés')
    end
  end
end
