require 'spec_helper'

describe 'new_user/dossiers/identite.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise, :with_service, state: Dossier.states.fetch(:brouillon), procedure: create(:procedure, :with_two_type_de_piece_justificative, for_individual: true)) }
  let(:footer) { view.content_for(:footer) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  context 'test de composition de la page' do
    before do
      render
    end

    it 'affiche les informations de la démarche' do
      expect(rendered).to have_text(dossier.procedure.libelle)
    end

    it 'prépare le footer' do
      expect(footer).to have_selector('footer')
    end
  end
end
