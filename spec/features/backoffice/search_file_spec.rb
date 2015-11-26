require 'spec_helper'

feature 'search file on gestionnaire backoffice' do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateur: administrateur) }

  before do
    login_as gestionnaire, scope: :gestionnaire
  end

  context 'when gestionnaire is logged in' do
    context 'when he click on search button' do
      let(:terms) { '' }

      before do
        visit backoffice_dossiers_a_traiter_url
        page.find_by_id(:q).set terms
        page.find_by_id(:search_button).click
      end

      it { expect(page).to have_css('#backoffice_search') }

      context 'when terms input is empty' do
        it { expect(page).to have_content('Aucun dossier trouvé') }
      end

      context 'when terms input is informed' do
        let(:terms) { 'test' }

        it 'terms stay in input after search' do
          expect(page.find_by_id('q').value).to eq(terms)
        end

        context 'when terms input does not return result' do
          it { expect(page).to have_content('Aucun dossier trouvé') }
        end

        context 'when terms input does return result' do
          let!(:procedure) { create(:procedure, administrateur: administrateur) }
          let!(:dossier) { create(:dossier, :with_entreprise, :with_user, procedure: procedure, state: 'initiated') }
          let!(:dossier_2) { create(:dossier, :with_user, procedure: procedure, state: 'initiated', nom_projet: 'Projet de test') }

          let(:terms) { dossier.nom_projet }

          it { expect(page).not_to have_content('Projet de test') }

          it { expect(page).to have_content(dossier.nom_projet) }

          context "when terms is a file's id" do
            let(:terms) { dossier.id }

            it { expect(page).to have_content("Dossier N°#{dossier.id}") }
          end
        end
      end
    end
  end
end