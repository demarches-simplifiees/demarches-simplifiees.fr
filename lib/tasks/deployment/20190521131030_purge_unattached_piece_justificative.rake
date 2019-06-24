namespace :after_party do
  desc 'Deployment task: purge_unattached_piece_justificative'
  task purge_unattached_piece_justificative: :environment do
    puts "Running deploy task 'purge_unattached_piece_justificative'"

    piece_justificatives = PieceJustificative.where(type_de_piece_justificative_id: nil)
    progress = ProgressReport.new(piece_justificatives.count)
    piece_justificatives.find_each do |pj|
      # detach from dossier to ensure we do not trigger touch
      pj.update_column(:dossier_id, nil)
      pj.remove_content!
      pj.destroy
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190521131030'
  end
end
