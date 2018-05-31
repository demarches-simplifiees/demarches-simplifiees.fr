class AvisMailer < ApplicationMailer
  def avis_invitation(avis)
    @avis = avis
    email = @avis.gestionnaire&.email || @avis.email
    mail(to: email, subject: "Donnez votre avis sur le dossier nº #{@avis.dossier.id} (#{@avis.dossier.procedure.libelle})")
  end
end
