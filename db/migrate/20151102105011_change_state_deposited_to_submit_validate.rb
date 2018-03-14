class ChangeStateDepositedToSubmitValidate < ActiveRecord::Migration[5.2]
  def change
    # Dossier.where(state: 'deposited').update_all(state: 'submit_validated')
  end
end
