class AvisMailer < ApplicationMailer

  def you_are_invited_on_dossier(avis)
    @avis = avis
    email = @avis.gestionnaire.try(:email) || @avis.email
    mail(to: email, subject: "Donnez votre avis sur le dossier nº #{@avis.dossier.id} (#{@avis.dossier.procedure.libelle})")
  end

end
