require 'spec_helper'

feature 'when gestionnaire come to /backoffice and is not authenticated' do
  let(:procedure) { create(:procedure, :published) }
  let!(:dossier) { create(:dossier, procedure: procedure) }
  before do
    visit backoffice_path
  end
  scenario 'he is redirected to /gestionnaires/sign_id' do
    expect(page).to have_css('#user_email')
  end
  context 'when user enter bad credentials' do
    before do
      page.find_by_id(:user_email).set 'unknown@plop.com'
      page.find_by_id(:user_password).set 'password'
      page.click_on 'Se connecter'
    end
    scenario 'he stay on the same page with an error' do
      expect(page).to have_content('Mauvais couple login / mot de passe')
    end
  end
  context 'when user enter good credentials' do
    let(:administrateur) { create(:administrateur) }
    let(:gestionnaire) { create(:gestionnaire, administrateurs: [administrateur]) }

    before do
      create :assign_to, gestionnaire: gestionnaire, procedure: procedure
      page.find_by_id(:user_email).set gestionnaire.email
      page.find_by_id(:user_password).set gestionnaire.password
      page.click_on 'Se connecter'
    end
    scenario 'he is redirected to /procedures' do
      expect(current_path).to eq(procedures_path)
    end
  end
end
