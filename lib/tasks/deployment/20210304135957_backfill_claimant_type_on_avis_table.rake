namespace :after_party do
  desc 'Deployment task: backfill_claimant_type_on_avis_table'
  task backfill_claimant_type_on_avis_table: :environment do
    puts "Running deploy task 'backfill_claimant_type_on_avis_table'"

    with_dossiers = Avis.where(claimant_type: nil).includes(claimant: :assign_to).where.not(claimant: { assign_tos: { id: nil } })
    with_dossiers.update_all(claimant_type: 'Instructeur')

    without_dossiers = Avis.where(claimant_type: nil).includes(claimant: :assign_to).where(claimant: { assign_tos: { id: nil } })
    without_dossiers.find_each do |avis|
      user = Instructeur.find(avis.claimant_id).user
      if user && avis.experts_procedure_id.blank?
        User.create_or_promote_to_expert(user.email, SecureRandom.hex)
        user.reload
        experts_procedure = ExpertsProcedure.find_or_create_by(procedure: avis.procedure, expert: user.expert)
        avis.update_columns(claimant_type: 'Expert', experts_procedure_id: experts_procedure.id, claimant_id: user.expert.id)
      elsif user && avis.experts_procedure_id.present?
        avis.update_column(:claimant_type, 'Expert')
      elsif user.blank?
        avis.destroy
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end