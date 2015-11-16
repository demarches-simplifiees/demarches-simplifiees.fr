class CreateReferenceAdmninistrateurToProcedure < ActiveRecord::Migration
  def change
    add_reference :procedures, :administrateur, references: :procedures
  end
end
