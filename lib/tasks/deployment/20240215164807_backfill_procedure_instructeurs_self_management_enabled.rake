namespace :after_party do
  desc 'Deployment task: backfill_procedure_instructeurs_self_management_enabled'
  task backfill_procedure_instructeurs_self_management_enabled: :environment do
    puts "Running deploy task 'backfill_procedure_instructeurs_self_management_enabled'"

    # rubocop:disable DS/Unscoped
    procedures = Procedure.unscoped.all
    # rubocop:enable DS/Unscoped
    progress = ProgressReport.new(procedures.count)

    Procedure.find_each do |procedure|
      procedure.update_column(:instructeurs_self_management_enabled, procedure.routing_enabled?)
      progress.inc(1)
    end

    progress.finish
  end
end
