class CreateNotification < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
      t.boolean :already_read, default: false
      t.string :liste, array: true
      t.boolean :multiple, default: false
      t.string :type_notif
      t.datetime :created_at
      t.datetime :updated_at
    end

    add_belongs_to :notifications, :dossier
  end
end
