require 'spec_helper'

describe 'users/carte/show.html.haml', type: :view do
  let(:state) { Dossier.states.fetch(:brouillon) }
  let(:dossier) { create(:dossier, state: state) }
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

    it 'la carte est bien présente' do
      expect(rendered).to have_selector('#map')
    end

    context 'présence des inputs hidden' do
      it 'stockage du json des polygons dessinés' do
        expect(rendered).to have_selector('input[type=hidden][id=json_latlngs][name=json_latlngs]', visible: false)
      end
    end

    context 'si la page précédente n\'est pas la page du dossier' do
      it 'le bouton "Etape suivante" est présent' do
        expect(rendered).to have_selector('#etape_suivante')
      end

      # it 'le bouton Etape suivante possède un onclick correct' do
      #   expect(rendered).to have_selector('input[type=submit][id=etape_suivante][onclick=\'submit_check_draw(event)\']')
      # end
    end

    context 'si la page précédente est la page du dossier' do
      let(:state) { Dossier.states.fetch(:en_construction) }

      it 'le bouton "Etape suivante" n\'est pas présent' do
        expect(rendered).to_not have_selector('#etape_suivante')
      end

      it 'le bouton "Modification terminé" est présent' do
        expect(rendered).to have_selector('#modification_terminee')
      end

      # it 'le bouton "Modification terminé" possède un onclick correct' do
      #   expect(rendered).to have_selector('input[type=submit][id=modification_terminee][onclick=\'submit_check_draw(event)\']')
      # end

      it 'le lien de retour à la page du dossier est présent' do
        expect(rendered).to have_selector("a[href='/dossiers/#{dossier_id}']")
      end
    end
  end
end
