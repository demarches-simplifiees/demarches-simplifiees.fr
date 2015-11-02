class ChangeStateProposedToSubmitted < ActiveRecord::Migration
  def change
    Dossier.where(state: 'proposed').update_all(state: 'submitted')
  end
end
