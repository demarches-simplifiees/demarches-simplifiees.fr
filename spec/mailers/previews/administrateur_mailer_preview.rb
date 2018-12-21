class AdministrateurMailerPreview < ActionMailer::Preview
  def activate_before_expiration
    administrateur = Administrateur.new
    administrateur.reset_password_sent_at = Time.now.utc

    AdministrateurMailer.activate_before_expiration(administrateur, "a4d4e4f4b4d445")
  end
end
