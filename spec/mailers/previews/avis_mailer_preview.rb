# Preview all emails at http://localhost:3000/rails/mailers/avis_mailer
class AvisMailerPreview < ActionMailer::Preview
  def avis_invitation
    AvisMailer.avis_invitation(Avis.last)
  end
end
