require Rails.root.join("lib", "tasks", "task_helper")

namespace :pieces_justificatives do
  task migrate_procedure_to_champs: :environment do
    procedure_id = ENV['PROCEDURE_ID']
    service = PieceJustificativeToChampPieceJointeMigrationService.new
    service.ensure_correct_storage_configuration!
    service.convert_procedure_pjs_to_champ_pjs(Procedure.find(procedure_id))
  end

  task migrate_procedures_range_to_champs: :environment do
    if ENV['RANGE_START'].nil? || ENV['RANGE_END'].nil?
      fail "RANGE_START and RANGE_END must be specified"
    end
    procedures_range = ENV['RANGE_START']..ENV['RANGE_END']

    service = PieceJustificativeToChampPieceJointeMigrationService.new
    service.ensure_correct_storage_configuration!
    procedures_to_migrate = service.procedures_with_pjs_in_range(procedures_range)

    procedures_to_migrate.find_each do |procedure|
      rake_puts ''
      rake_puts "Migrating procedure #{procedure.id}…"

      service.convert_procedure_pjs_to_champ_pjs(procedure)
    end
  end
end
