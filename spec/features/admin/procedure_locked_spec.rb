require 'spec_helper'

feature 'procedure locked' do
  let(:administrateur) { create(:administrateur) }
  let (:published_at) { nil }
  let(:procedure) { create(:procedure, administrateur: administrateur, published_at: published_at) }

  before do
    login_as administrateur, scope: :administrateur
    visit admin_procedure_path(procedure)
  end

  context 'when procedure is not published' do
    scenario 'info label is not present' do
      expect(page).not_to have_content('Cette démarche a été publiée, certains éléments ne peuvent plus être modifiés')
    end
  end
end
