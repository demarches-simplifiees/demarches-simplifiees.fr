class DeleteAllMailValidatedInDb < ActiveRecord::Migration[5.0]
  def change
    mail_template_exist = Object.const_get(:MailTemplate).is_a?(Class) rescue false
    MailTemplate.where(type: "MailValidated").delete_all if mail_template_exist
  end
end
