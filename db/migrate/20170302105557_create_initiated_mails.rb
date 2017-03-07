class CreateInitiatedMails < ActiveRecord::Migration[5.0]
  def change
    create_table :initiated_mails do |t|
      t.text :object
      t.text :body
      t.belongs_to :procedure, index: true, unique: true, foreign_key: true

      t.column  :created_at, :timestamp, null: true
      t.column  :updated_at, :timestamp, null: true
    end
  end
end
