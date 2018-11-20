# Preview all emails at http://localhost:3000/rails/mailers/avis_mailer
class AvisMailer < ApplicationMailer
  def avis_invitation(avis)
    @avis = avis
    email = @avis.gestionnaire&.email || @avis.email
    subject = "Donnez votre avis sur le dossier nº #{@avis.dossier.id} (#{@avis.dossier.procedure.libelle})"

    mail(to: email, subject: subject)
  end
end
