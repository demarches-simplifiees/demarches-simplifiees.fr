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
end
