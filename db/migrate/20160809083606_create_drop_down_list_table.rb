class CreateDropDownListTable < ActiveRecord::Migration[5.2]
  def change
    create_table :drop_down_lists do |t|
      t.string :value
      t.belongs_to :type_de_champ
    end
  end
end
