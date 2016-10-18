require 'spec_helper'

feature 'on click on tabs button' do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }

  let(:procedure) { create :procedure, administrateur: administrateur }

  before do
    create(:dossier, :with_entreprise, procedure: procedure, state: 'initiated')
    create(:dossier, :with_entreprise, procedure: procedure, state: 'replied')
    create(:dossier, :with_entreprise, procedure: procedure, state: 'updated')
    create(:dossier, :with_entreprise, procedure: procedure, state: 'validated')
    create(:dossier, :with_entreprise, procedure: procedure, state: 'submitted')
    create(:dossier, :with_entreprise, procedure: procedure, state: 'received')
    create(:dossier, :with_entreprise, procedure: procedure, state: 'closed')
    create(:dossier, :with_entreprise, procedure: procedure, state: 'refused')
    create(:dossier, :with_entreprise, procedure: procedure, state: 'without_continuation')

    create :assign_to, gestionnaire: gestionnaire, procedure: procedure

    login_as gestionnaire, scope: :gestionnaire
  end

  context 'when gestionnaire is logged in' do
    context 'when he click on tabs nouveaux' do
      before do
        visit backoffice_dossiers_url(liste: :nouveaux)
        page.click_on 'Nouveaux 1'
      end

      scenario 'it redirect to backoffice dossier termine' do
        expect(page).to have_css('#backoffice_index')
      end
    end

    context 'when he click on tabs a traite' do
      before do
        visit backoffice_dossiers_url(liste: :a_traiter)
        page.click_on 'Action requise 1'
      end

      scenario 'it redirect to backoffice dossier termine' do
        expect(page).to have_css('#backoffice_index')
      end
    end

    context 'when he click on tabs en attente' do
      before do
        visit backoffice_dossiers_url(liste: :en_attente)
        page.click_on 'Attente usager 2'
      end

      scenario 'it redirect to backoffice dossier en attente' do
        expect(page).to have_css('#backoffice_index')
      end
    end

    context 'when he click on tabs a receptionner' do
      before do
        visit backoffice_dossiers_url(liste: :deposes)
        page.click_on 'À réceptionner 1'
      end

      scenario 'it redirect to backoffice dossier a_receptionner' do
        expect(page).to have_css('#backoffice_index')
      end
    end

    context 'when he click on tabs a instruire' do
      before do
        visit backoffice_dossiers_url(liste: :a_instruire)
        page.click_on 'À instruire 1'
      end

      scenario 'it redirect to backoffice dossier termine' do
        expect(page).to have_css('#backoffice_index')
      end
    end

    context 'when he click on tabs termine' do
      before do
        visit backoffice_dossiers_url(liste: :termine)
        page.click_on 'Terminé 3'
      end

      scenario 'it redirect to backoffice dossier termine' do
        expect(page).to have_css('#backoffice_index')
      end
    end
  end

  context "OpenSimplif" do
    before do
      allow(Features).to receive(:opensimplif).and_return(true)
      visit backoffice_dossiers_url
    end

    scenario "it hides the tabs" do
      expect(page).to_not have_css('#filter_by_procedure')
      expect(page).to_not have_css('#onglets')
    end
  end
end
