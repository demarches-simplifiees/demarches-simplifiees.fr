class ChangeProcedureAutoArchiveDateToDatetime < ActiveRecord::Migration[5.0]
  def up
    change_column :procedures, :auto_archive_on, :datetime
  end

  def down
    change_column :procedures, :auto_archive_on, :date
  end
end
