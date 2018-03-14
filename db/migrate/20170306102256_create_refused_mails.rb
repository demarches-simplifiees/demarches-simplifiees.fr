class CreateRefusedMails < ActiveRecord::Migration[5.2]
  def change
    create_table :refused_mails do |t|
      t.text :body
      t.string :object
      t.belongs_to :procedure, index: true, unique: true, foreign_key: true

      t.timestamps
    end
  end
end
