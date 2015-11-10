require 'spec_helper'

feature 'when gestionnaire come to /backoffice and is not authenticated' do
  let(:procedure) { create(:procedure) }
  let!(:dossier) { create(:dossier, :with_user, procedure: procedure) }
  before do
    visit backoffice_path
  end
  scenario 'he is redirected to /gestionnaires/sign_id' do
    expect(page).to have_css('#gestionnaire_login')
  end
  context 'when user enter bad credentials' do
    before do
      page.find_by_id(:gestionnaire_email).set 'unknown@plop.com'
      page.find_by_id(:gestionnaire_password).set 'password'
      page.click_on 'Se connecter'
    end
    scenario 'he stay on the same page with an error' do
      expect(page).to have_content('email ou mot de passe incorrect.')
    end
  end
  context 'when user enter good credentials' do
    let(:administrateur) { create(:administrateur) }
    let(:gestionnaire) { create(:gestionnaire, administrateur: administrateur) }

    before do
      page.find_by_id(:gestionnaire_email).set  gestionnaire.email
      page.find_by_id(:gestionnaire_password).set  gestionnaire.password
      page.click_on 'Se connecter'
    end
    scenario 'he is redirected to /backoffice' do
      expect(page).to have_css('#backoffice')
    end
  end
end