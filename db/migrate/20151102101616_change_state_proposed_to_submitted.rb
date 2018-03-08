class ChangeStateProposedToSubmitted < ActiveRecord::Migration[5.2]
  def change
    Dossier.where(state: 'proposed').update_all(state: 'submitted')
  end
end
