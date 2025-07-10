class CreateTypesDeChampProceduresJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_join_table :types_de_champ, :procedures
  end
end
