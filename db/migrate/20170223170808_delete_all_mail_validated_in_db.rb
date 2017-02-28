class DeleteAllMailValidatedInDb < ActiveRecord::Migration[5.0]
  def change
    MailTemplate.where(type: "MailValidated").delete_all
  end
end
