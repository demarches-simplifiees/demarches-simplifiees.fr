# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_expert_id_on_avis_table'
  task backfill_experts_procedure_id_on_avis_table: :environment do
    puts "Running deploy task 'backfill_experts_procedure_id_on_avis_table'"
    # rubocop:disable DS/Unscoped
    # rubocop:disable Rails/PluckInWhere

    instructeurs = Instructeur.includes(:user).where.not(users: { instructeur_id: nil })

    instructeurs =
      if Avis.column_names.include?("instructeur_id")
        instructeurs.where(id: Avis.unscoped.pluck(:instructeur_id))
      else
        instructeurs.where(id: Avis.unscoped.where(claimant_type: [nil, "Instructeur"]).pluck(:claimant_id))
      end

    instructeurs.find_each do |instructeur|
      user = instructeur.user
      User.create_or_promote_to_expert(user.email, SecureRandom.hex)
      user.reload
      # rubocop:enable DS/Unscoped
      # rubocop:enable Rails/PluckInWhere
      Avis.where(claimant: instructeur).find_each do |avis|
        experts_procedure = ExpertsProcedure.find_or_create_by(expert: user.expert, procedure: avis.procedure)
        avis.update_column(:experts_procedure_id, experts_procedure.id)
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
