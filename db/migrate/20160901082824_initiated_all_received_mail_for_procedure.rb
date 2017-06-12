class InitiatedAllReceivedMailForProcedure < ActiveRecord::Migration
  class Procedure < ActiveRecord::Base
    has_one :mail_received
  end

  class MailTemplate < ActiveRecord::Base
  end

  class ::MailReceived < MailTemplate
    before_save :default_values

    def default_values
      self.object ||= "[TPS] Accusé de réception pour votre dossier nº --numero_dossier--"
      self.body ||= "Bonjour,
                    <br>
                    <br>
                    Votre administration vous confirme la bonne réception de votre dossier nº--numero_dossier-- complet. Celui-ci sera instruit dans le délais légal déclaré par votre interlocuteur.<br>
                    <br>
                    En vous souhaitant une bonne journée,
                    <br>
                    <br>
                    ---
                    <br>
                    L'équipe TPS"
    end
  end

  def up
    Procedure.all.each do |procedure|
      procedure.mail_received ||= MailReceived.create(type: 'MailReceived')
      procedure.save
    end
  end

  def down
    Procedure.all.each do |procedure|
      procedure.mail_received.delete
    end
  end
end
