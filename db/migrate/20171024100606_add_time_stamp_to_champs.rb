class AddTimeStampToChamps < ActiveRecord::Migration[5.0]
  def change
    add_column :champs, :created_at, :datetime
    add_column :champs, :updated_at, :datetime
  end
end
