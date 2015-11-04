class ChangeStateSubmittedToInitiated < ActiveRecord::Migration
  def change
    Dossier.where(state: 'submitted').update_all(state: 'initiated')
  end
end
