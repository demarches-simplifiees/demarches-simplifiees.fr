# frozen_string_literal: true

require Rails.root.join("lib", "tasks", "task_helper")

namespace :re_routing_dossiers do
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
