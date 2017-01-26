class MailValidated < MailTemplate
  before_save :default_values

  def default_values
    self.object ||= "[TPS] Votre dossier TPS N°--numero_dossier-- a été validé"
    self.body ||= "Bonjour,<br>
                    <br>
                    Votre dossier N°--numero_dossier-- est prêt à être déposé pour instruction.<br>
                    <br>
                    Afin de finaliser son dépôt, merci de vous rendre sur --lien_dossier--.,<br>
                    <br>
                    Bonne journée,<br>
                    ---<br>
                    Merci de ne pas répondre à ce mail. Postez directement vos questions dans votre dossier sur la plateforme.<br>
                    ---<br>
                    L'équipe TPS"
  end
end
