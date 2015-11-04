class ChangeStateConfirmedToValidated < ActiveRecord::Migration
  def change
    Dossier.where(state: 'confirmed').update_all(state: 'validated')

  end
end
