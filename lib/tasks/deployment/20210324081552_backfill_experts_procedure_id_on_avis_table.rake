# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_experts_procedure_id_on_avis_table'
  task backfill_experts_procedure_id_on_avis_table_again: :environment do
    puts "Running deploy task 'backfill_experts_procedure_id_on_avis_table_again'"

    if Avis.column_names.include?("instructeur_id")
      without_instructeur = Avis.where(experts_procedure_id: nil, instructeur_id: nil).where.not(email: nil)
      with_instructeur = Avis.where(experts_procedure_id: nil, email: nil).where.not(instructeur_id: nil)
    else
      without_instructeur = Avis
        .where(experts_procedure_id: nil, claimant_type: [nil, "Instructeur"])
        .where.not(email: nil)

      with_instructeur = Avis
        .where(experts_procedure_id: nil, email: nil, claimant_type: [nil, "Instructeur"])
        .where.not(claimant_id: nil)
    end

    progress = ProgressReport.new(without_instructeur.count)
    progress2 = ProgressReport.new(with_instructeur.count)

    without_instructeur.find_each do |avis|
      # if the avis email is valid then we create the associated expert
      email = avis.email.strip
      if Devise.email_regexp.match?(email)
        user = User.create_or_promote_to_expert(email, SecureRandom.hex)
        user.reload
        experts_procedure = ExpertsProcedure.find_or_create_by!(procedure: avis.dossier.procedure, expert: user.expert)
        avis.update_column(:experts_procedure_id, experts_procedure.id)
      end
      progress.inc
    end
    progress.finish

    with_instructeur.find_each do |avis|
      instructeur = avis.respond_to?(:instructeur) ? avis.instructeur : avis.claimant

      if instructeur && instructeur.user
        user = User.create_or_promote_to_expert(instructeur.user.email, SecureRandom.hex)
        user.reload
        experts_procedure = ExpertsProcedure.find_or_create_by!(procedure: avis.dossier.procedure, expert: user.expert)
        avis.update_column(:experts_procedure_id, experts_procedure.id)
      end
      progress2.inc
    end
    progress2.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
