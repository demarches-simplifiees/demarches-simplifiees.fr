class AddNomToTypeDeChamp < ActiveRecord::Migration[6.1]
  def change
    add_column :types_de_champ, :nom, :string, default: "", null: false
  end
end
