require Rails.root.join("lib", "tasks", "task_helper")

namespace :pieces_justificatives do
  desc <<~EOD
    Migrate the PJ to champs for a single PROCEDURE_ID.
  EOD
  task migrate_procedure_to_champs: :environment do
    procedure_id = ENV['PROCEDURE_ID']
    procedure = Procedure.find(procedure_id)

    service = PieceJustificativeToChampPieceJointeMigrationService.new
    service.ensure_correct_storage_configuration!

    progress = ProgressReport.new(service.number_of_champs_to_migrate(procedure))

    service.convert_procedure_pjs_to_champ_pjs(procedure) do
      progress.inc
    end

    progress.finish
  end

  desc <<~EOD
    Migrate the PJ to champs for several procedures ids, from RANGE_START to RANGE_END.
  EOD
  task migrate_procedures_range_to_champs: :environment do
    if ENV['RANGE_START'].nil? || ENV['RANGE_END'].nil?
      fail "RANGE_START and RANGE_END must be specified"
    end
    procedures_range = ENV['RANGE_START']..ENV['RANGE_END']

    service = PieceJustificativeToChampPieceJointeMigrationService.new
    service.ensure_correct_storage_configuration!
    procedures_to_migrate = service.procedures_with_pjs_in_range(procedures_range)

    total_number_of_champs_to_migrate = procedures_to_migrate
      .map { |p| service.number_of_champs_to_migrate(p) }
      .sum
    progress = ProgressReport.new(total_number_of_champs_to_migrate)

    procedures_to_migrate.find_each do |procedure|
      rake_puts ''
      rake_puts "Migrating procedure #{procedure.id}…"

      service.convert_procedure_pjs_to_champ_pjs(procedure) do
        progress.inc
      end
    end

    progress.finish
  end
end
