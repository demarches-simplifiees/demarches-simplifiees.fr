class MoveMailsToNewSystem < ActiveRecord::Migration[5.2]
  def up
    execute 'INSERT INTO received_mails (object, body, procedure_id, created_at, updated_at)
      SELECT object, body, procedure_id, mail_templates.created_at, mail_templates.updated_at from mail_templates inner join procedures on mail_templates.procedure_id = procedures.id;'

    execute "UPDATE received_mails set created_at='1980-01-01 00:00', updated_at='1980-01-01 00:00' where created_at is NULL"

    change_column_null :received_mails, :created_at, false
    change_column_null :received_mails, :updated_at, false
  end
end
