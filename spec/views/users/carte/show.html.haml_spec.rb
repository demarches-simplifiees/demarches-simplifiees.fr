require 'spec_helper'

describe 'users/carte/show.html.haml', type: :view do
  let(:state) { 'draft' }
  let(:dossier) { create(:dossier, :with_procedure, :with_user, state: state) }
  let(:dossier_id) { dossier.id }
  
  before do
    assign(:dossier, dossier)
  end
  
  context 'sur la page de la carte d\'une demande' do
    before do
      render
    end
    it 'le formulaire envoie vers /users/dossiers/:dossier_id/carte en #POST' do
      expect(rendered).to have_selector("form[action='/users/dossiers/#{dossier_id}/carte'][method=post]")
    end
  
    it 'la page des sources CSS de l\'API carto est chargée' do
      expect(rendered).to have_selector('#sources_CSS_api_carto')
    end
  
    it 'la page des sources JS de l\'API carto est chargée' do
      expect(rendered).to have_selector('#sources_JS_api_carto')
    end
  
    it 'la carte est bien présente' do
      expect(rendered).to have_selector('#map_qp')
    end
  
    context 'présence des inputs hidden' do
      it 'stockage de la référence du dossie de l\'API carto' do
        expect(rendered).to have_selector('input[type=hidden][id=ref_dossier][name=ref_dossier]')
      end
    end
  
    context 'si la page précédente n\'est pas recapitulatif' do
      it 'le bouton "Etape suivante" est présent' do
        expect(rendered).to have_selector('#etape_suivante')
      end
  
      # it 'le bouton Etape suivante possède un onclick correct' do
      #   expect(rendered).to have_selector('input[type=submit][id=etape_suivante][onclick=\'submit_check_draw(event)\']')
      # end
    end
  
    context 'si la page précédente est recapitularif' do
      let(:state) { 'initiated' }

      it 'le bouton "Etape suivante" n\'est pas présent' do
        expect(rendered).to_not have_selector('#etape_suivante')
      end

      it 'le bouton "Modification terminé" est présent' do
        expect(rendered).to have_selector('#modification_terminee')
      end
  
      # it 'le bouton "Modification terminé" possède un onclick correct' do
      #   expect(rendered).to have_selector('input[type=submit][id=modification_terminee][onclick=\'submit_check_draw(event)\']')
      # end
  
      it 'le lien de retour au récapitulatif est présent' do
        expect(rendered).to have_selector("a[href='/users/dossiers/#{dossier_id}/recapitulatif']")
      end
    end
  end
end
