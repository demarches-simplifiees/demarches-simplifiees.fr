class ChangeStateConfirmedToValidated < ActiveRecord::Migration[5.2]
  def change
    # Dossier.where(state: 'confirmed').update_all(state: 'validated')
  end
end
