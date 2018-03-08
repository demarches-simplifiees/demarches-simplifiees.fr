class ChangeStateSubmitValidatedToSubmitted < ActiveRecord::Migration[5.2]
  def change
    Dossier.where(state: 'submit_validated').update_all(state: 'submitted')
  end
end
