class ChangeStateProcessedToClosed < ActiveRecord::Migration
  def change
    Dossier.where(state: 'processed').update_all(state: 'closed')
  end
end
