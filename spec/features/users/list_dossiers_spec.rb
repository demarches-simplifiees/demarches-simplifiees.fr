require 'spec_helper'

feature 'user access to the list of his dossier' do

  let(:user) { create(:user) }
  let!(:last_updated_dossier) { create(:dossier, :with_procedure, user: user)}
  let!(:dossier1) { create(:dossier, :with_procedure, user: user, nom_projet: 'mon permier dossier') }
  let!(:dossier2) { create(:dossier, :with_user, nom_projet: 'mon deuxième dossier') }
  before do
    last_updated_dossier.update_attributes(nom_projet: 'salut la compagnie')
    visit root_path
    page.find_by_id('user_email').set user.email
    page.find_by_id('user_password').set user.password
    page.click_on 'Se connecter'
  end
  scenario 'the list of dossier is displayed' do
    expect(page).to have_content(dossier1.nom_projet)
    expect(page).not_to have_content(dossier2.nom_projet)
  end

  scenario 'the list must be order by last updated' do
    expect(page.body).to match(/#{last_updated_dossier.nom_projet}.*#{dossier1.nom_projet}/m)
  end

  context 'when user clicks on a projet in list' do
    before do
      page.click_on dossier1.nom_projet
    end
    scenario 'user is redirected to dossier page' do
      expect(page).to have_css('#recap_dossier')
    end
  end
end