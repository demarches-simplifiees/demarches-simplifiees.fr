require 'spec_helper'

describe 'new_user/dossiers/modifier.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise, :with_service, state: 'brouillon', procedure: create(:procedure, :with_api_carto, :with_two_type_de_piece_justificative, for_individual: true)) }
  let(:footer) { view.content_for(:footer) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  context 'test de composition de la page' do
    before do
      render
    end

    it 'affiche le libellé de la procédure' do
      expect(rendered).to have_text(dossier.procedure.libelle)
    end

    it 'affiche les boutons de validation' do
      expect(rendered).to have_selector('.send-wrapper')
    end

    it 'prépare le footer' do
      expect(footer).to have_selector('footer')
    end
  end
end
