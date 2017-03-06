class CreateReceivedMails < ActiveRecord::Migration[5.0]
  def change
    create_table :received_mails do |t|
      t.text :body
      t.text :object
      t.references :procedure, foreign_key: true

      t.timestamps
    end
  end
end
