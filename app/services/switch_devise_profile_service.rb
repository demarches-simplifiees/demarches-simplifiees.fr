class SwitchDeviseProfileService
  def initialize(warden)
    @warden = warden
  end

  def multiple_devise_profile_connect?
    user_signed_in? && instructeur_signed_in? ||
        instructeur_signed_in? && administrateur_signed_in? ||
        user_signed_in? && administrateur_signed_in?
  end

  private

  def user_signed_in?
    @warden.authenticate(:scope => :user).present?
  end

  def instructeur_signed_in?
    @warden.authenticate(:scope => :instructeur).present?
  end

  def administrateur_signed_in?
    @warden.authenticate(:scope => :administrateur).present?
  end
end
