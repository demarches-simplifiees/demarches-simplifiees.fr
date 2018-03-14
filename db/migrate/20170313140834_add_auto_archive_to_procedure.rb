class AddAutoArchiveToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :auto_archive_on, :date
  end
end
