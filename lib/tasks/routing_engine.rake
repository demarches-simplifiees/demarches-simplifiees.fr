# frozen_string_literal: true

require Rails.root.join("lib", "tasks", "task_helper")

namespace :routing_engine do
  desc <<~EOD
    Given an id in argument, run the RoutingEngine for a dossier, after having set `forced_groupe_instructeur` field to false.
    ex: rails routing_engine:run\[1352684\]
  EOD
  task :run, [:dossier_id] => :environment do |_t, args|
    dossier = Dossier.find_by(id: args[:dossier_id])

    if dossier.present?
      dossier.update!(forced_groupe_instructeur: false)

      dossier.reload

      RoutingEngine.compute(dossier)

      rake_puts "Dossier #{args[:dossier_id]} routed to groupe instructeur #{dossier.groupe_instructeur.label}"
    else
      rake_puts "Dossier with id #{args[:dossier_id]} not found in db"
    end
  end
end
