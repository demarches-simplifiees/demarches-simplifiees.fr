class AdministrateurMailerPreview < ActionMailer::Preview
  def activate_before_expiration
    user = User.new(reset_password_sent_at: Time.zone.now)

    AdministrateurMailer.activate_before_expiration(user, "a4d4e4f4b4d445")
  end

  def notify_procedure_expires_when_termine_forced
    email = Administrateur.first.email
    procedure = Procedure.first
    AdministrateurMailer.notify_procedure_expires_when_termine_forced(email, procedure)
  end
end
