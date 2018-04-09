class AdministrateurMailerPreview < ActionMailer::Preview
  def activate_before_expiration
    AdministrateurMailer.activate_before_expiration(Administrateur.inactive.where.not(reset_password_token: nil).last)
  end
end
