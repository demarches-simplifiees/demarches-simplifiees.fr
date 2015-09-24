require 'spec_helper'

describe 'dossiers/_infos_dossier.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise, :with_procedure) }

  let(:maj_infos) { 'Mettre à jour les informations' }
  let(:proposer) { 'Soumettre mon dossier' }

  before do
    assign(:dossier, dossier.decorate)
    assign(:commentaires, dossier.commentaires)
    render
  end

  context 'dossier is at state Draft' do
    it 'button Mettre à jours les informations is present' do
      expect(rendered).to have_content(maj_infos)
      expect(rendered).to have_selector("a[href='/dossiers/#{dossier.id}/description?back_url=recapitulatif']");
    end
    it 'button Soumettre is present' do
      expect(rendered).to have_selector("button[type=submit][value='#{soumettre}']");
    end
  end
end
