describe 'user access to the list of their dossiers', js: true do
  let(:user) { create(:user) }
  let!(:dossier_brouillon)       { create(:dossier, user: user) }
  let!(:dossier_en_construction) { create(:dossier, :with_populated_champs, :en_construction, user: user) }
  let!(:dossier_en_instruction)  { create(:dossier, :en_instruction, user: user) }
  let!(:dossier_archived)        { create(:dossier, :en_instruction, :archived, user: user) }
  let(:dossiers_per_page) { 25 }
  let(:last_updated_dossier) { dossier_en_construction }

  before do
    @default_per_page = Dossier.default_per_page
    Dossier.paginates_per dossiers_per_page

    last_updated_dossier.update_column(:updated_at, "19/07/2052 15:35".to_time)

    login_as user, scope: :user
    visit dossiers_path
  end

  after do
    Dossier.paginates_per @default_per_page
  end

  it 'the list of dossier is displayed' do
    expect(page).to have_content(dossier_brouillon.procedure.libelle)
    expect(page).to have_content(dossier_en_construction.procedure.libelle)
    expect(page).to have_content(dossier_en_instruction.procedure.libelle)
    expect(page).to have_content(dossier_archived.procedure.libelle)
  end

  it 'the list must be ordered by last updated' do
    expect(page.body).to match(/#{last_updated_dossier.procedure.libelle}.*#{dossier_en_instruction.procedure.libelle}/m)
  end

  context 'when there are dossiers from other users' do
    let!(:dossier_other_user) { create(:dossier) }

    it 'doesn’t display dossiers belonging to other users' do
      expect(page).not_to have_content(dossier_other_user.procedure.libelle)
    end
  end

  context 'when there is more than one page' do
    let(:dossiers_per_page) { 2 }

    scenario 'the user can navigate through the other pages' do
      expect(page).not_to have_content(dossier_en_instruction.procedure.libelle)
      page.click_link("Suivant")
      expect(page).to have_content(dossier_en_instruction.procedure.libelle)
    end
  end

  context 'when user clicks on a projet in list' do
    before do
      page.click_on(dossier_en_construction.procedure.libelle)
    end

    scenario 'user is redirected to dossier page' do
      expect(page).to have_current_path(dossier_path(dossier_en_construction))
    end
  end

  describe 'deletion' do
    it 'should have links to delete dossiers' do
      expect(page).to have_link(nil, href: delete_dossier_dossier_path(dossier_brouillon))
      expect(page).to have_link(nil, href: delete_dossier_dossier_path(dossier_en_construction))
      expect(page).not_to have_link(nil, href: delete_dossier_dossier_path(dossier_en_instruction))
    end

    context 'when user clicks on delete button', js: true do
      scenario 'the dossier is deleted' do
        within(:css, "tr[data-dossier-id=\"#{dossier_brouillon.id}\"]") do
          click_on 'Actions'
          page.accept_alert('Confirmer la suppression ?') do
            click_on 'Supprimer le dossier'
          end
        end

        expect(page).to have_content('Votre dossier a bien été supprimé')
        expect(page).not_to have_content(dossier_brouillon.procedure.libelle)
      end
    end
  end

  describe "recherche" do
    context "when the dossier does not exist" do
      before do
        page.find_by_id('q').set(10000000)
        find('.fr-search-bar .fr-btn').click
      end

      it "shows an error message on the dossiers page" do
        expect(current_path).to eq(dossiers_path)
        expect(page).to have_content("Vous n’avez pas de dossiers contenant « 10000000 ».")
      end
    end

    context "when the dossier does not belong to the user" do
      let!(:dossier_other_user) { create(:dossier) }

      before do
        page.find_by_id('q').set(dossier_other_user.id)
        find('.fr-search-bar .fr-btn').click
      end

      it "shows an error message on the dossiers page" do
        expect(current_path).to eq(dossiers_path)
        expect(page).to have_content("Vous n’avez pas de dossiers contenant « #{dossier_other_user.id} ».")
      end
    end

    context "when the dossier belongs to the user" do
      before do
        page.find_by_id('q').set(dossier_en_construction.id)
        find('.fr-search-bar .fr-btn').click
      end

      it "redirects to the dossier page" do
        expect(current_path).to eq(dossier_path(dossier_en_construction))
      end
    end

    context "when user search for something inside the dossier" do
      let(:dossier_en_construction2) { create(:dossier, :with_populated_champs, :en_construction, user: user) }
      before do
        page.find_by_id('q').set(dossier_en_construction.champs.first.value)
      end

      context 'when it only matches one dossier' do
        before do
          find('.fr-search-bar .fr-btn').click
        end
        it "redirects to the dossier page" do
          expect(current_path).to eq(dossier_path(dossier_en_construction))
        end
      end

      context 'when it matches multiple dossier' do
        before do
          dossier_en_construction2.champs.first.update(value: dossier_en_construction.champs.first.value)
          find('.fr-search-bar .fr-btn').click
        end

        it "redirects to the search results" do
          expect(current_path).to eq(recherche_dossiers_path)
          expect(page).to have_content(dossier_en_construction.id)
          expect(page).to have_content(dossier_en_construction2.id)
        end
      end
    end
  end
end
