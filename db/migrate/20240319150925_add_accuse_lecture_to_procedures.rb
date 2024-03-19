class AddAccuseLectureToProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :accuse_lecture, :boolean, default: false, null: false
  end
end
