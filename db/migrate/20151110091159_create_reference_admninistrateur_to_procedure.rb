class CreateReferenceAdmninistrateurToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_reference :procedures, :administrateur, references: :procedures
  end
end
