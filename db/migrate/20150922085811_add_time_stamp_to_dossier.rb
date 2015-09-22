class AddTimeStampToDossier < ActiveRecord::Migration
  def change
    add_column :dossiers, :created_at, :datetime, default: Time.now
    add_column :dossiers, :updated_at, :datetime, default: Time.now
  end
end
