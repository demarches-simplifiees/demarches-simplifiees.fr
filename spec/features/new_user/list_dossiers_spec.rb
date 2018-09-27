require 'spec_helper'

describe 'user access to the list of his dossier' do
  let(:user) { create(:user) }
  let!(:last_updated_dossier) { create(:dossier, :with_entreprise, user: user, state: Dossier.states.fetch(:en_construction)) }
  let!(:dossier1) { create(:dossier, :with_entreprise, user: user, state: Dossier.states.fetch(:en_construction)) }
  let!(:dossier2) { create(:dossier, :with_entreprise) }
  let!(:dossier_archived) { create(:dossier, :with_entreprise, user: user, state: Dossier.states.fetch(:en_construction)) }
  let(:dossiers_per_page) { 25 }

  before do
    @default_per_page = Dossier.default_per_page
    Dossier.paginates_per dossiers_per_page

    last_updated_dossier.update_column(:updated_at, "19/07/2052 15:35".to_time)

    visit new_user_session_path
    within('#new_user') do
      page.find_by_id('user_email').set user.email
      page.find_by_id('user_password').set user.password
      page.click_on 'Se connecter'
    end
  end

  after do
    Dossier.paginates_per @default_per_page
  end

  it 'the list of dossier is displayed' do
    expect(page).to have_content(dossier1.procedure.libelle)
    expect(page).to have_content('en construction')
  end

  it 'dossiers belonging to other users are not displayed' do
    expect(page).not_to have_content(dossier2.procedure.libelle)
  end

  it 'the list must be ordered by last updated' do
    expect(page.body).to match(/#{last_updated_dossier.procedure.libelle}.*#{dossier1.procedure.libelle}/m)
  end

  it 'should list archived dossiers' do
    expect(page).to have_content(dossier_archived.procedure.libelle)
  end

  context 'when user clicks on a projet in list', js: true do
    before do
      page.click_on(dossier1.procedure.libelle)
    end
    scenario 'user is redirected to dossier page' do
      expect(page).to have_current_path(dossier_path(dossier1))
    end
  end

  context 'when there is more than one page' do
    let(:dossiers_per_page) { 2 }

    scenario 'the user can navigate through the other pages', js: true do
      page.click_link("Suivant")
      expect(page).to have_content(dossier_archived.procedure.libelle)
    end
  end

  describe "recherche" do
    context "when the dossier does not exist" do
      before do
        page.find_by_id('dossier_id').set(10000000)
        click_button("Rechercher")
      end

      it "shows an error message on the dossiers page" do
        expect(current_path).to eq(dossiers_path)
        expect(page).to have_content("Vous n’avez pas de dossier avec le nº 10000000.")
      end
    end

    context "when the dossier does not belong to the user" do
      before do
        page.find_by_id('dossier_id').set(dossier2.id)
        click_button("Rechercher")
      end

      it "shows an error message on the dossiers page" do
        expect(current_path).to eq(dossiers_path)
        expect(page).to have_content("Vous n’avez pas de dossier avec le nº #{dossier2.id}.")
      end
    end

    context "when the dossier belongs to the user" do
      before do
        page.find_by_id('dossier_id').set(dossier1.id)
        click_button("Rechercher")
      end

      it "redirects to the dossier page" do
        expect(current_path).to eq(dossier_path(dossier1))
      end
    end
  end
end
