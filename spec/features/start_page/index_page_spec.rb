require 'spec_helper'

feature 'Start#Index Page' do
  context 'si personne n\'est connecté' do
    before do
      visit root_path
    end

    scenario 'la section des professionnels est présente' do
      expect(page).to have_selector('#pro_section')
    end

    scenario 'la section des admin est présente' do
      expect(page).to have_selector('#admin_section')
    end

    context 'dans la section professionnel' do
      scenario 'le formulaire envoie vers /dossiers en #POST' do
        expect(page).to have_selector("form[action='/dossiers'][method=post]")
      end

      scenario 'le champs "Numéro SIRET" est présent' do
        expect(page).to have_selector('input[id=siret][name=siret]')
      end

      scenario 'le champs "Numéro de dossier" n\'est pas visible' do
        expect(page).to_not have_selector('input[id=pro_dossier_id][name=pro_dossier_id]')
      end

      scenario 'button "j\'ai déjà un numéro de dossier "' do
        expect(page).to have_selector('#btn_show_dossier_id_input')
      end

      scenario 'le champs "Numéro SIRET" ne peut contenir que 15 caractères' do
        length_string_20 = SecureRandom.hex(10)
        find('#siret').set(length_string_20)

        expect(find('#siret').value.length).to eq(14)
      end
    end

    context 'dans la section admninistration' do
      scenario 'le formulaire envoie vers /login en #POST' do
        expect(page).to have_selector("form[action='/login'][method=post]")
      end

      scenario ' le champs "Identifiant" est présent' do
        expect(page).to have_selector("input[id=user_email][name='user[email]']")
      end

      scenario 'le champs "Mot de passe" est présent' do
        expect(page).to have_selector("input[id=user_password][name='user[password]']")
      end

      scenario 'le champs "Mot de passe" est de type password' do
        expect(page).to have_selector('input[type=password][id=user_password]')
      end

      scenario 'le champs "Numéro de dossier" est présent' do
        expect(page).to have_selector('input[id=dossier_id][name=dossier_id]')
      end
    end
  end

  context 'si une administration est connecté' do
    before do
      login_admin
      visit root_path
    end

    scenario 'la section des professionnels n\'est pas présente' do
      expect(page).to_not have_selector('#pro_section')
    end

    scenario 'la section des admin est présente' do
      expect(page).to have_selector('#admin_section')
    end

    context 'dans la section admninistration' do
      scenario 'le formulaire envoie vers /admin/dossier en #GET' do
        expect(page).to have_selector("form[action='/admin/dossier'][method=get]")
      end

      scenario ' le champs "Identifiant" n\'est pas présent' do
        expect(page).to_not have_selector("input[id=user_email][name='user[email]']")
      end

      scenario 'le champs "Mot de passe" n\'est pas présent' do
        expect(page).to_not have_selector("input[id=user_password][name='user[password]']")
      end

      scenario 'le champs "Numéro de dossier" est présent' do
        expect(page).to have_selector('input[id=dossier_id][name=dossier_id]')
      end
    end
  end
end