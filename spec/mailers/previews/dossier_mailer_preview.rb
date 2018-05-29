# Preview all emails at http://localhost:3000/rails/mailers/dossier_mailer
class DossierMailerPreview < ActionMailer::Preview
  def ask_deletion
    DossierMailer.ask_deletion(Dossier.last)
  end
end
