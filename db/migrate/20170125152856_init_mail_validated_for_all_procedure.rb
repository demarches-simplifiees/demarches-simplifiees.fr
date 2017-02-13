class InitMailValidatedForAllProcedure < ActiveRecord::Migration[5.0]
  def change
    Procedure.all.each do |p|
      unless p.mail_validated
        p.mail_templates << MailValidated.create
      end
    end
  end
end
