require Rails.root.join("lib", "tasks", "task_helper")

namespace :re_routing_dossiers do
  desc <<~EOD
    Given an procedure id in argument, run the RoutingEngine again for all "en construction" dossiers of the procedure
    ex: rails re_routing_dossiers:run\[85869\]
  EOD

  task :run, [:procedure_id] => :environment do |_t, args|
    procedure = Procedure.find_by(id: args[:procedure_id])

    dossiers = procedure.dossiers.state_en_construction

    progress = ProgressReport.new(dossiers.count)

    assignment_mode = DossierAssignment.modes.fetch(:tech)

    dossiers.each do |dossier|
      RoutingEngine.compute(dossier, assignment_mode:)

      rake_puts "Dossier #{dossier.id} routed to groupe instructeur #{dossier.groupe_instructeur.label}"

      progress.inc
    end
    progress.finish
  end
end
