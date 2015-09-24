require 'spec_helper'

feature 'Description#Show Page' do
  let(:user) { create(:user) }
  let(:dossier) { create(:dossier, :with_procedure, user: user) }
  let(:dossier_id) { dossier.id }

  before do
    visit users_dossier_description_path(dossier_id: dossier_id)
  end

  context 'tous les attributs sont présents sur la page' do
    scenario 'Le formulaire envoie vers /users/dossiers/:dossier_id/description en #POST' do
      expect(page).to have_selector("form[action='/users/dossiers/#{dossier_id}/description'][method=post]")
    end

    scenario 'Nom du projet' do
      expect(page).to have_selector('input[id=nom_projet][name=nom_projet]')
    end

    scenario 'Description du projet' do
      expect(page).to have_selector('textarea[id=description][name=description]')
    end

    scenario 'Montant du projet' do
      expect(page).to have_selector('input[id=montant_projet][name=montant_projet]')
    end

    scenario 'Montant du projet est de type number' do
      expect(page).to have_selector('input[type=number][id=montant_projet]')
    end

    scenario 'Montant des aides du projet' do
      expect(page).to have_selector('input[id=montant_aide_demande][name=montant_aide_demande]')
    end

    scenario 'Montant des aides du projet est de type number' do
      expect(page).to have_selector('input[type=number][id=montant_aide_demande]')
    end

    scenario 'Date prévisionnelle du projet' do
      expect(page).to have_selector('input[id=date_previsionnelle][name=date_previsionnelle]')
    end

    scenario 'Date prévisionnelle du projet est de type text avec un data-provide=datepicker' do
      expect(page).to have_selector('input[type=text][id=date_previsionnelle][data-provide=datepicker]')
    end

    scenario 'Charger votre CERFA (PDF)' do
      expect(page).to have_selector('input[type=file][name=cerfa_pdf][id=cerfa_pdf]')
    end

    scenario 'Lien CERFA' do
      expect(page).to have_selector('#lien_cerfa')
    end
  end

  context 'si la page précédente n\'est pas recapitulatif' do
    scenario 'le bouton "Terminer" est présent' do
      expect(page).to have_selector('#suivant')
    end
  end

  context 'si la page précédente est recapitularif' do
    before do
      visit "/users/dossiers/#{dossier_id}/description?back_url=recapitulatif"
    end

    scenario 'le bouton "Terminer" n\'est pas présent' do
      expect(page).to_not have_selector('#suivant')
    end

    scenario 'input hidden back_url a pour valeur le params GET' do
      expect(page).to have_selector('input[type=hidden][id=back_url][value=recapitulatif]')
    end

    scenario 'le bouton "Modification terminé" est présent' do
      expect(page).to have_selector('#modification_terminee')
    end

    scenario 'le lien de retour au récapitulatif est présent' do
      expect(page).to have_selector("a[href='/dossiers/#{dossier_id}/recapitulatif']")
    end
  end

  context 'les valeurs sont réaffichées si elles sont présentes dans la BDD' do
    let!(:dossier) do
      create(:dossier, :with_procedure,
             nom_projet: 'Projet de test',
             description: 'Description de test',
             montant_projet: 12_000,
             montant_aide_demande: 3000,
             date_previsionnelle: '20/01/2016',
             user: user)
    end

    scenario 'Nom du projet' do
      expect(page).to have_selector("input[id=nom_projet][value='#{dossier.nom_projet}']")
    end

    scenario 'Description du projet' do
      expect(page).to have_content("#{dossier.description}")
    end

    scenario 'Montant du projet' do
      expect(page).to have_selector("input[id=montant_projet][value='#{dossier.montant_projet}']")
    end

    scenario 'Montant des aides du projet' do
      expect(page).to have_selector("input[id=montant_aide_demande][value='#{dossier.montant_aide_demande}']")
    end

    scenario 'Date prévisionnelle du projet' do
      expect(page).to have_selector("input[id=date_previsionnelle][value='#{dossier.date_previsionnelle}']")
    end
  end

  context 'Pièces justificatives' do
    let(:all_type_pj_procedure_id) { dossier.procedure.type_de_piece_justificative_ids }

    context 'la liste des pièces justificatives a envoyé est affichée' do
      it 'RIB' do
        expect(page).to have_selector("input[type=file][name=piece_justificative_#{all_type_pj_procedure_id[0]}][id=piece_justificative_#{all_type_pj_procedure_id[0]}]")
      end
    end

    context 'la liste des pièces récupérées automatiquement est signaliée' do
      it 'Attestation MSA' do
        expect(page.find_by_id("piece_justificative_#{all_type_pj_procedure_id[1]}")).to have_content('Nous l\'avons récupéré pour vous.')
      end
    end
  end
end
