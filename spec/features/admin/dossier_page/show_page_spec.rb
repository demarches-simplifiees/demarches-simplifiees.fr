require 'spec_helper'

feature 'Admin/Dossier#Show Page' do
  let(:dossier_id){10000}

  before do
    login_admin
    visit "/admin/dossier/#{dossier_id}"
  end

  context 'sur la page admin du dossier' do
    scenario 'la section infos entreprise est présente' do
      expect(page).to have_selector('#infos_entreprise')
    end

    scenario 'la section infos dossier est présente' do
      expect(page).to have_selector('#infos_dossier')
    end

    scenario 'le numéro de dossier est présent sur la page' do
      expect(page).to have_selector('#dossier_id')
      expect(page).to have_content(dossier_id)
    end

    context 'les liens de modifications sont non présent' do
      scenario 'le lien vers carte' do
        expect(page).to_not have_selector('a[id=modif_carte]')
      end

      scenario 'le lien vers description' do
        expect(page).to_not have_selector('a[id=modif_description]')
      end
    end

    scenario 'la carte est bien présente' do
      expect(page).to have_selector('#map_qp');
    end

    scenario 'la page des sources CSS de l\'API cart est chargée' do
      expect(page).to have_selector('#sources_CSS_api_carto')
    end

    scenario 'la page des sources JS backend de l\'API cart est chargée' do
      expect(page).to have_selector('#sources_JS_api_carto_backend')
    end
  end
end