require 'spec_helper'

describe 'start/index.html.haml', type: :view do
  context 'si personne n\'est connecté' do
    before do
      render
    end

    it 'la section des professionnels est présente' do
      expect(rendered).to have_selector('#pro_section')
    end

    context 'dans la section professionnel' do
      it 'le formulaire envoie vers /dossiers en #POST' do
        expect(rendered).to have_selector("form[action='/dossiers'][method=post]")
      end

      it 'le champs "Numéro SIRET" est présent' do
        expect(rendered).to have_selector('input[id=siret][name=siret]')
      end

      it 'le titre de la procédure' do
        expect(rendered).to have_selector('#titre_procedure')
      end
    end
  end
end