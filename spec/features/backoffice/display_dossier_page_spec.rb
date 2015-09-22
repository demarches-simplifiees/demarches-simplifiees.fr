require 'spec_helper'

feature 'Admin/Dossier#Show Page' do
  let!(:dossier) { create(:dossier, :with_entreprise, :with_procedure) }
  let(:dossier_id) { dossier.id }

  before do
    login_gestionnaire
    visit "/backoffice/dossiers/#{dossier_id}"
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

    # context 'la liste des pièces justificatives est présente' do
    #   context 'Attestation MSA' do
    #     let(:id_piece_justificative) { 93 }
    #
    #     scenario 'la ligne de la pièce justificative est présente' do
    #       expect(page).to have_selector("tr[id=piece_justificative_#{id_piece_justificative}]")
    #     end
    #
    #     scenario 'le bouton "Récupérer" est présent' do
    #       expect(page.find("tr[id=piece_justificative_#{id_piece_justificative}]")).to have_selector("a[href='']")
    #       expect(page.find("tr[id=piece_justificative_#{id_piece_justificative}]")).to have_content('Récupérer')
    #     end
    #   end
    #
    #   context 'Attestation RDI' do
    #     let(:id_piece_justificative) { 103 }
    #
    #     scenario 'la ligne de la pièce justificative est présente' do
    #       expect(page).to have_selector("tr[id=piece_justificative_#{id_piece_justificative}]")
    #     end
    #
    #     scenario 'le libelle "Pièce manquante" est présent' do
    #       expect(page.find("tr[id=piece_justificative_#{id_piece_justificative}]")).to have_content('Pièce non fournie')
    #     end
    #   end
    #
    #   context 'Devis' do
    #     let(:id_piece_justificative) { 388 }
    #     let(:content) { File.open('./spec/support/files/piece_justificative_388.pdf') }
    #
    #     before do
    #       piece_justificative = dossier.pieces_justificatives.where(type_de_piece_justificative_id: 388).first
    #       piece_justificative.content = content
    #       piece_justificative.save!
    #       visit "/admin/dossiers/#{dossier_id}"
    #     end
    #
    #     scenario 'la ligne de la pièce justificative est présente' do
    #       expect(page).to have_selector("tr[id=piece_justificative_#{id_piece_justificative}]")
    #     end
    #
    #     scenario 'le libelle "Consulter" est présent' do
    #       expect(page.find("tr[id=piece_justificative_#{id_piece_justificative}] a")[:href]).to have_content('piece_justificative_388.pdf')
    #       expect(page.find("tr[id=piece_justificative_#{id_piece_justificative}]")).to have_content('Consulter')
    #     end
    #   end
    # end

    scenario 'la carte est bien présente' do
      expect(page).to have_selector('#map_qp')
    end

    scenario 'la page des sources CSS de l\'API cart est chargée' do
      expect(page).to have_selector('#sources_CSS_api_carto')
    end

    scenario 'la page des sources JS backend de l\'API cart est chargée' do
      expect(page).to have_selector('#sources_JS_api_carto_backend')
    end
  end
end
