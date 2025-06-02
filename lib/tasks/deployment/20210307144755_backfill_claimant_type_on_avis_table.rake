# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_claimant_type_on_avis_table'
  task backfill_claimant_type_on_avis_table: :environment do
    puts "Running deploy task 'backfill_claimant_type_on_avis_table'"

    BATCH_SIZE = 20000

    without_assign_to_ids = Instructeur.includes(:assign_to).where(assign_tos: { id: nil }).pluck(:id)
    with_dossiers = Avis.where(claimant_type: nil).where.not(claimant_id: without_assign_to_ids)

    ((with_dossiers.count / BATCH_SIZE).ceil + 1).times do
      with_dossiers
        .limit(BATCH_SIZE)
        .update_all(claimant_type: 'Instructeur')
    end

    without_dossiers = Avis.where(claimant_type: nil).where(claimant_id: without_assign_to_ids)
    without_dossiers.find_each do |avis|
      instructeur = Instructeur.find(avis.claimant_id)

      if instructeur && avis.experts_procedure_id.blank?
        User.create_or_promote_to_expert(instructeur.user.email, SecureRandom.hex)
        instructeur.user.reload
        experts_procedure = ExpertsProcedure.find_or_create_by(procedure: avis.procedure, expert: instructeur.user.expert)
        avis.update_columns(claimant_type: 'Expert', experts_procedure_id: experts_procedure.id)

      elsif instructeur.blank? && avis.experts_procedure_id.blank?
        expert = User.create_or_promote_to_expert(avis.email, SecureRandom.hex).expert
        expert.reload
        experts_procedure = ExpertsProcedure.find_or_create_by(procedure: avis.procedure, expert: expert)
        avis.update_columns(claimant_type: 'Expert', experts_procedure_id: experts_procedure.id)

      elsif avis.experts_procedure_id.present?
        avis.update_column(:claimant_type, 'Expert')

      elsif instructeur && instructeur.user.nil?
        avis.destroy
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
