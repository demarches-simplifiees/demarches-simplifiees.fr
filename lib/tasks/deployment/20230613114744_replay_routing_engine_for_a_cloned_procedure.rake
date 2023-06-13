namespace :after_party do
  desc 'Deployment task: replay_routing_engine_for_a_cloned_procedure'
  task replay_routing_engine_for_a_cloned_procedure: :environment do
    puts "Running deploy task 'replay_routing_engine_for_a_cloned_procedure'"

    # Put your task implementation HERE.
    dossiers = Procedure
      .find(76266)
      .dossiers
      .en_construction

    progress = ProgressReport.new(dossiers.count)

    dossiers.find_each do |dossier|
      RoutingEngine.compute(dossier)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
