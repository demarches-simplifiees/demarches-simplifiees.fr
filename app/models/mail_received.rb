class MailReceived < MailTemplate
  before_save :default_values


  def name
    "E-mail d'accusé de réception"
  end

  def default_values
    self.object ||= "[TPS] Accusé de réception pour votre dossier n°--numero_dossier--"
    self.body ||= "Bonjour,
                    <br>
                    <br>
                    Votre administration vous confirme la bonne réception de votre dossier n°--numero_dossier-- complet. Celui-ci sera instruit dans le délai légal déclaré par votre interlocuteur.<br>
                    <br>
                    En vous souhaitant une bonne journée,
                    <br>
                    <br>
                    ---
                    <br>
                    L'équipe TPS"
  end
end
