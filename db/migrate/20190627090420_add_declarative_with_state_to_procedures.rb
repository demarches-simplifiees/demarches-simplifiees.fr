class AddDeclarativeWithStateToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :declarative_with_state, :string
    add_index :procedures, :declarative_with_state
  end
end
