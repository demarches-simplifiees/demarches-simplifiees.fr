namespace :'2019_03_13_migrate_pjs_to_champs' do
  task run: :environment do
    procedure_id = ENV['PROCEDURE_ID']
    service = PieceJustificativeToChampPieceJointeMigrationService.new
    service.ensure_correct_storage_configuration!
    service.convert_procedure_pjs_to_champ_pjs(Procedure.find(procedure_id))
  end
end
