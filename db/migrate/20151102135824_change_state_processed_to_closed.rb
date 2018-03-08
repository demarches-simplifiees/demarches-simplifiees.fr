class ChangeStateProcessedToClosed < ActiveRecord::Migration[5.2]
  def change
    Dossier.where(state: 'processed').update_all(state: 'closed')
  end
end
