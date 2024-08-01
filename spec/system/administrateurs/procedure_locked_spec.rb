# frozen_string_literal: true

describe 'procedure locked' do
  let(:administrateur) { administrateurs(:default_admin) }

  before do
    login_as administrateur.user, scope: :user
    visit admin_procedure_publication_path(procedure)
  end

  context 'when procedure is not published' do
    let(:procedure) { create(:procedure, administrateur: administrateur) }

    scenario 'info label is not present' do
      expect(page).to have_content('Publier')
      expect(page).not_to have_content('Cette démarche est publiée, certains éléments ne peuvent plus être modifiés.')
    end
  end

  context 'when procedure is published' do
    let(:procedure) { create(:procedure, :published, administrateur: administrateur) }

    scenario 'info label is present' do
      expect(page).to have_content('Publier')
      expect(page).to have_content('Cette démarche est publiée, certains éléments ne peuvent plus être modifiés.')
    end
  end
end
