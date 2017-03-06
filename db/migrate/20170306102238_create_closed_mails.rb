class CreateClosedMails < ActiveRecord::Migration[5.0]
  def change
    create_table :closed_mails do |t|
      t.text :body
      t.text :object
      t.belongs_to :procedure, index: true, unique: true, foreign_key: true

      t.timestamps
    end
  end
end
