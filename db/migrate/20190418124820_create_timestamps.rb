class CreateTimestamps < ActiveRecord::Migration[5.2]
  def change
    create_table :timestamps do |t|
      t.text :signature
      t.daterange :period

      t.timestamps
    end
  end
end
