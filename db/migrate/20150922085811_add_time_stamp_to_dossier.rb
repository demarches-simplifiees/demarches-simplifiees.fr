class AddTimeStampToDossier < ActiveRecord::Migration
  def change
    add_column :dossiers, :created_at, :datetime
    add_column :dossiers, :updated_at, :datetime
  end
end
