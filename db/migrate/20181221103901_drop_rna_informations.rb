class DropRNAInformations < ActiveRecord::Migration[5.2]
  def change
    drop_table :rna_informations
  end
end
