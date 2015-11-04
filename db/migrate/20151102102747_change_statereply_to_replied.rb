class ChangeStatereplyToReplied < ActiveRecord::Migration
  def change
    Dossier.where(state: 'reply').update_all(state: 'replied')
  end
end
