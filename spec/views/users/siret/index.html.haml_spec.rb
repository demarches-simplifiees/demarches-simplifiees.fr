require 'spec_helper'

describe 'users/siret/index.html.haml', type: :view do
  let(:procedure) { create(:procedure, libelle: 'Demande de subvention') }
  before do
    assign(:procedure, procedure)
    render
  end

  it 'la section des professionnels est présente' do
    expect(rendered).to have_selector('#pro_section')
  end

  context 'dans la section professionnel' do
    it 'le formulaire envoie vers /dossiers en #POST' do
      expect(rendered).to have_selector("form[action='/users/dossiers'][method=post]")
    end

    it 'le champs "Numéro SIRET" est présent' do
      expect(rendered).to have_selector('input[id=siret][name=siret]')
    end

    it 'le titre de la procédure' do
      expect(rendered).to have_selector('#titre-procedure')
    end

    context 'stockage de l\'ID de la procédure dans un champs hidden' do
      it {expect(rendered).to have_selector("input[type=hidden][id=procedure_id][name=procedure_id][value='#{procedure.id}']", visible: false)}
    end

    it 'le titre de la procédure est présent sur la page' do
      expect(rendered).to have_content(procedure.libelle)
    end
  end
end
