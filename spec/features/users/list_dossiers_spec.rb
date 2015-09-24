require 'spec_helper'

feature 'user access to the list of his dossier' do

  let(:user) { create(:user) }
  let!(:dossier1) { create(:dossier, :with_user) }
  before do
    visit root_path
    page.find_by_id('user_email').set user.email
    page.find_by_id('user_password').set user.password
    page.click_on 'Se connecter'
  end
  scenario 'the list of dossier is displayed' do
    expect(page).to have_content(dossier1.nom_projet)
  end
end