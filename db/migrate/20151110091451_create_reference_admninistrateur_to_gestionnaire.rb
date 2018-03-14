class CreateReferenceAdmninistrateurToGestionnaire < ActiveRecord::Migration[5.2]
  def change
    add_reference :gestionnaires, :administrateur, references: :gestionnaires
  end
end
