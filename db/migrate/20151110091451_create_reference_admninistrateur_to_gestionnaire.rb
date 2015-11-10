class CreateReferenceAdmninistrateurToGestionnaire < ActiveRecord::Migration
  def change
    add_reference :gestionnaires, :administrateur, references: :gestionnaires
  end
end
