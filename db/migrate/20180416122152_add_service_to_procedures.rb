class AddServiceToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_reference :procedures, :service, foreign_key: true
  end
end
