class CreateReceivedMails < ActiveRecord::Migration[5.0]
  def change
    create_table :received_mails do |t|
      t.text :body
      t.string :object
      t.references :procedure, foreign_key: true

      t.column  :created_at, :timestamp, null: true
      t.column  :updated_at, :timestamp, null: true
    end
  end
end
