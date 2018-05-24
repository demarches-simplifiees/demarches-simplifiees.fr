class DossierMailer < ApplicationMailer
  layout 'mailers/layout'

  def ask_deletion(dossier)
    @dossier = dossier
    mail(to: "contact@demarches-simplifiees.fr", subject: "Demande de suppression de dossier")
  end
end
