# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: backfill_hide_instructeurs_email'
  task backfill_hide_instructeurs_email: :environment do
    puts "Running deploy task 'backfill_hide_instructeurs_email'"

    feature_name = "hide_instructeur_email"
    feature = Flipper.feature(feature_name)

    gates = Flipper::Adapters::ActiveRecord::Gate
      .where(feature_key: feature.key, key: 'actors')

    total_gates = gates.count
    progress = ProgressReport.new(total_gates)

    puts 'Collecte des démarches avec le feature flag'

    procedure_ids = gates.ids
    puts procedure_ids

    progress.finish

    puts progress

    puts "Mise à jour des #{procedure_ids.size} démarches"
    update_progress = ProgressReport.new(procedure_ids.size)

    Procedure.where(id: procedure_ids).in_batches(of: 500) do |batch|
      batch.update_all(hide_instructeurs_email: true)
      update_progress.inc(batch.size)
      puts update_progress
    end

    update_progress.finish
    puts update_progress

    puts "Suppression du feature flag '#{feature_name}'"
    Flipper.remove(feature_name)
    puts "Feature flag '#{feature_name}' supprimé avec succès"

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
