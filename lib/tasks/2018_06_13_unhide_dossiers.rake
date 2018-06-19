namespace :'2018_06_13_unhide_dossiers' do
  task run: :environment do
    Dossier.unscoped.where.not(hidden_at: nil).state_instruction_commencee.each do |d|
      if !d.procedure.nil? # ensure the procedure was not deleted by administrateur for testing
        d.update(hidden_at: nil)
        DeletedDossier.find_by(dossier_id: d.id)&.destroy
        DossierMailer.notify_unhide_to_user(d).deliver_later
      end
    end
  end
end
