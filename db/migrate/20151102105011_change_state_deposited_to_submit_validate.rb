class ChangeStateDepositedToSubmitValidate < ActiveRecord::Migration
  def change
    Dossier.where(state: 'deposited').update_all(state: 'submit_validated')
  end
end
