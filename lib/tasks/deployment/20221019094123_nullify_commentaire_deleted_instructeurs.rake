# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: nullify_commentaire_deleted_instructeurs'
  task nullify_commentaire_deleted_instructeurs: :environment do
    puts "Running deploy task 'nullify_commentaire_deleted_instructeurs'"

    commentaires_without_instructeurs = Commentaire.where.missing(:instructeur).where.not(instructeur_id: nil)
    progress = ProgressReport.new(commentaires_without_instructeurs.count)

    commentaires_without_instructeurs.in_batches do |commentaires|
      count = commentaires.count
      commentaires.update_all(instructeur_id: nil)
      progress.inc(count)
    end
    progress.finish

    commentaires_without_experts = Commentaire.where.missing(:expert).where.not(expert_id: nil)
    progress = ProgressReport.new(commentaires_without_experts.count)

    commentaires_without_experts.in_batches do |commentaires|
      count = commentaires.count
      commentaires.update_all(expert_id: nil)
      progress.inc(count)
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
