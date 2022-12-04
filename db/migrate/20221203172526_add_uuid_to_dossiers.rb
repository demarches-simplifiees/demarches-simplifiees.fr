class AddUuidToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :uuid, :uuid, null: true, unique: true
  end
end
