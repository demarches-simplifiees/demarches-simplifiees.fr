module FeatureHelpers
  include ActiveJob::TestHelper

  def login_admin
    user = create :user
    login_as user, scope: :user
    user
  end

  def login_gestionnaire
    gestionnaire = create(:gestionnaire)
    login_as gestionnaire, scope: :gestionnaire
  end

  def create_dossier
    dossier = FactoryBot.create(:dossier)
    dossier
  end

  def sign_in_with(email, password)
    fill_in :user_email, with: email
    fill_in :user_password, with: password
    click_on 'Se connecter'
  end

  def sign_up_with(email, password = 'testpassword')
    fill_in :user_email, with: email
    fill_in :user_password, with: password

    perform_enqueued_jobs do
      click_button 'Créer un compte'
    end
  end

  def click_confirmation_link_for(email)
    confirmation_email = open_email(email)
    token_params = confirmation_email.body.match(/confirmation_token=[^"]+/)

    visit "/users/confirmation?#{token_params}"
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
