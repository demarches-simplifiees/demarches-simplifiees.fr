class ChangeStateSubmittedToInitiated < ActiveRecord::Migration[5.2]
  def change
    Dossier.where(state: 'submitted').update_all(state: 'initiated')
  end
end
