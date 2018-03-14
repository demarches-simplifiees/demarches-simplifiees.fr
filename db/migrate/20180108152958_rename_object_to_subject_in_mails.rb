class RenameObjectToSubjectInMails < ActiveRecord::Migration[5.2]
  def change
    rename_column :closed_mails, :object, :subject
    rename_column :initiated_mails, :object, :subject
    rename_column :received_mails, :object, :subject
    rename_column :refused_mails, :object, :subject
    rename_column :without_continuation_mails, :object, :subject
  end
end
