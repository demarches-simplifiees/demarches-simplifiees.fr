class AddMandatoryToTypeDeChamps < ActiveRecord::Migration[5.2]
  def change
    add_column :types_de_champ, :mandatory, :boolean, default: false
  end
end
