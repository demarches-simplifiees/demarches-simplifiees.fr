require 'spec_helper'

feature 'Description#Show Page' do
  let(:dossier) { create(:dossier) }
  let(:dossier_id) { dossier.id }

  before do
    dossier.build_default_pieces_jointes
    visit "/dossiers/#{dossier_id}/description"
  end

  context 'tous les attributs sont présents sur la page' do
    scenario 'Le formulaire envoie vers /dossiers/:dossier_id/description en #POST' do
      expect(page).to have_selector("form[action='/dossiers/#{dossier_id}/description'][method=post]")
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

    scenario 'Mail de contact' do
      expect(page).to have_selector('input[id=mail_contact][name=mail_contact]')
    end

    scenario 'Mail de contact est de type mail' do
      expect(page).to have_selector('input[type=email][id=mail_contact]')
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
      expect(page).to have_selector('#suivant');
    end
  end

  context 'si la page précédente est recapitularif' do
    before do
      visit "/dossiers/#{dossier_id}/description?back_url=recapitulatif"
    end

    scenario 'le bouton "Terminer" n\'est pas présent' do
      expect(page).to_not have_selector('#suivant');
    end

    scenario 'input hidden back_url a pour valeur le params GET' do
      expect(page).to have_selector('input[type=hidden][id=back_url][value=recapitulatif]')
    end

    scenario 'le bouton "Modification terminé" est présent' do
      expect(page).to have_selector('#modification_terminee');
    end

    scenario 'le lien de retour au récapitulatif est présent' do
      expect(page).to have_selector("a[href='/dossiers/#{dossier_id}/recapitulatif']")
    end
  end

  context 'les valeurs sont réaffichées si elles sont présentes dans la BDD' do
    let(:dossier) do
      create(:dossier,
             nom_projet: 'Projet de test',
             description: 'Description de test',
             montant_projet: 12_000,
             montant_aide_demande: 3000,
             date_previsionnelle: '20/01/2016',
             mail_contact: 'test@test.com')
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

    scenario 'Mail de contact' do
      expect(page).to have_selector("input[id=mail_contact][value='#{dossier.mail_contact}']")
    end
  end

  context 'Pièces jointes' do
    context 'la liste des pièces jointes a envoyé est affichée' do
      it 'Attestation RDI' do
        expect(page).to have_selector('input[type=file][name=piece_jointe_103][id=piece_jointe_103]')
      end

      it 'Devis' do
        expect(page).to have_selector('input[type=file][name=piece_jointe_388][id=piece_jointe_388]')
      end

      it 'Pièce d\'identité' do
        expect(page).to have_selector('input[type=file][name=piece_jointe_692][id=piece_jointe_692]')
      end

      it 'Plan de transmission du capital social' do
        expect(page).to have_selector('input[type=file][name=piece_jointe_764][id=piece_jointe_764]')
      end

      it 'RIB ou RIP' do
        expect(page).to have_selector('input[type=file][name=piece_jointe_849][id=piece_jointe_849]')
      end
    end

    context 'la liste des pièces récupérées automatiquement est signaliée' do
      it 'Attestation MSA' do
        expect(page.find_by_id('piece_jointe_93')).to have_content('Nous l\'avons récupéré pour vous.')
      end

      it 'KBIS' do
        expect(page.find_by_id('piece_jointe_571')).to have_content('Nous l\'avons récupéré pour vous.')
      end
    end
  end
end