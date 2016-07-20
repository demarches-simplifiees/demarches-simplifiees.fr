require 'spec_helper'

feature 'search file on gestionnaire backoffice' do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }

  before do
    login_as gestionnaire, scope: :gestionnaire
  end

  context 'when gestionnaire is logged in' do
    context 'when he click on search button' do
      let(:terms) { '' }
      let!(:procedure) { create(:procedure, administrateur: administrateur) }

      before do
        create :assign_to, gestionnaire: gestionnaire, procedure: procedure

        visit backoffice_dossiers_url
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
          let!(:dossier) { create(:dossier, :with_entreprise,  procedure: procedure, state: 'initiated') }
          let!(:dossier_2) { create(:dossier,  procedure: procedure, state: 'initiated') }

          let(:terms) { dossier.entreprise.raison_sociale }

          it { expect(page).to have_content(dossier.entreprise.raison_sociale) }

          context "when terms is a file's id" do
            let(:terms) { dossier.id }

            it { expect(page).to have_content("Dossier N°#{dossier.id}") }
          end
        end
      end
    end
  end
end