namespace :'2018_05_15_add_aasm_state_to_procedure' do
  task set: :environment do
    Procedure.archivees.update_all(aasm_state: :archivee)
    Procedure.publiees.update_all(aasm_state: :publiee)
    Procedure.brouillons.update_all(aasm_state: :brouillon)
    Procedure.unscoped.where.not(hidden_at: nil).update_all(aasm_state: :hidden)
  end
end
