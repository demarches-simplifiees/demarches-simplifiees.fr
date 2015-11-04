class ChangeStateSubmitValidatedToSubmitted < ActiveRecord::Migration
  def change
    Dossier.where(state: 'submit_validated').update_all(state: 'submitted')
  end
end
