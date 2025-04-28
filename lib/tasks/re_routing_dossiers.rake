# frozen_string_literal: true

require Rails.root.join("lib", "tasks", "task_helper")

namespace :re_routing_dossiers do
  desc <<~EOD
    Given a procedure id in argument, run the RoutingEngine again for all dossiers of the procedure (included all states of dossier).
    This task should be used only if field(s) used for routing have not been changed in procedure revisions. Otherwise, dossiers might be routed the wrong way.
    Please check history of procedure revisions before using this task.
    Consider running previously the task below reset_forced_groupe_instructeur, if manual reaffectations should be reset or not.
    ex: rails re_routing_dossiers:run\[85869\]
  EOD

  task :run, [:procedure_id] => :environment do |_t, args|
    procedure = Procedure.find_by(id: args[:procedure_id])

    dossiers = procedure.dossiers

    progress = ProgressReport.new(dossiers.count)

    assignment_mode = DossierAssignment.modes.fetch(:tech)

    dossiers.each do |dossier|
      RoutingEngine.compute(dossier, assignment_mode:)

      rake_puts "Dossier #{dossier.id} routed to groupe instructeur #{dossier.groupe_instructeur.label}"

      progress.inc
    end
    progress.finish
  end

  desc <<~EOD
    Given a procedure id in argument, reset value of forced_groupe_instructeur to false for all dossiers.
    ex: rails re_routing_dossiers:reset_forced_groupe_instructeur\[85869\]
  EOD
  task :reset_forced_groupe_instructeur, [:procedure_id] => :environment do |_t, args|
    procedure = Procedure.find_by(id: args[:procedure_id])

    dossiers = procedure.dossiers

    progress = ProgressReport.new(dossiers.count)

    dossiers.each do |dossier|
      if dossier.update(forced_groupe_instructeur: false)
        rake_puts "Dossier #{dossier.id} updated with forced_groupe_instructeur to false"

        progress.inc
      end
    end
    progress.finish
  end
end
