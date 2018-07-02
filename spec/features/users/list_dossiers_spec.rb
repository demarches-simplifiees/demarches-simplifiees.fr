require 'spec_helper'

describe 'user access to the list of his dossier' do
  let(:user) { create(:user) }
  let!(:last_updated_dossier) { create(:dossier, :with_entreprise, user: user, state: 'en_construction') }
  let!(:dossier1) { create(:dossier, :with_entreprise, user: user, state: 'en_construction') }
  let!(:dossier2) { create(:dossier, :with_entreprise) }
  let!(:dossier_archived) { create(:dossier, :with_entreprise, user: user, state: 'en_construction') }
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
      expect(page).to have_css('#users-recapitulatif-dossier-show')
    end
  end

  context 'when there is more than one page' do
    let(:dossiers_per_page) { 2 }

    scenario 'the user can navigate through the other pages', js: true do
      page.click_link("Suivant")
      expect(page).to have_content(dossier_archived.procedure.libelle)
    end

    scenario 'the user sees a card asking for feedback' do
      expect(page).to have_css('.card.feedback')
      expect(page).to have_content(CONTACT_EMAIL)
    end
  end
end
