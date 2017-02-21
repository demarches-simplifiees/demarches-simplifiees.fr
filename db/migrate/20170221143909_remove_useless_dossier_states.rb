class RemoveUselessDossierStates < ActiveRecord::Migration[5.0]
  def change
    Dossier.where(state: [:validated, :submitted]).update_all(state: :initiated)
  end
end
