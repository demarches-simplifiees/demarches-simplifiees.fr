namespace :after_party do
  desc 'Deployment task: backfill_experts_procedure_id_missing_on_avis'
  task backfill_experts_procedure_id_missing_on_avis: :environment do
    puts "Running deploy task 'backfill_experts_procedure_id_missing_on_avis'"

    without_instructeur = Avis.where(experts_procedure_id: nil, answer: nil, instructeur_id: nil).where.not(email: nil)
    with_instructeur = Avis.where(experts_procedure_id: nil, answer: nil, email: nil).where.not(instructeur_id: nil)
    progress = ProgressReport.new(without_instructeur.count)
    progress2 = ProgressReport.new(with_instructeur.count)

    without_instructeur.find_each do |avis|
      # if the avis email is valid then we create the associated expert
      if Devise.email_regexp.match?(avis.email)
        user = User.create_or_promote_to_expert(avis.email, SecureRandom.hex)
        user.reload
        experts_procedure = ExpertsProcedure.find_or_create_by(procedure: avis.dossier.procedure, expert: user.expert)
        avis.update_column(:experts_procedure_id, experts_procedure.id)
      end
      progress.inc
    end
    progress.finish

    with_instructeur.find_each do |avis|
      instructeur = avis.instructeur
      if instructeur && instructeur.user
        user = User.create_or_promote_to_expert(instructeur.user.email, SecureRandom.hex)
        user.reload
        experts_procedure = ExpertsProcedure.find_or_create_by(procedure: avis.dossier.procedure, expert: user.expert)
        avis.update_column(:experts_procedure_id, experts_procedure.id)
      end
      progress2.inc
    end
    progress2.finish

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
