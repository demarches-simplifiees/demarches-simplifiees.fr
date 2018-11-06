module FeatureHelpers
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
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
