module FeatureHelpers
  def login_admin
    user = User.first
    login_as user, scope: :user
    user
  end

  def create_dossier
    dossier = FactoryGirl.create(:dossier)
    dossier
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end