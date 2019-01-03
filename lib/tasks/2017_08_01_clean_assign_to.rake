namespace :'2017_08_01_clean_assign_to' do
  task clean: :environment do
    duplicates = AssignTo.group(:gestionnaire_id, :procedure_id).count.select { |_gestionnaire_id_procedure_id, count| count > 1 }.keys

    duplicate_ids = duplicates.map { |gestionnaire_id, procedure_id| AssignTo.where(gestionnaire_id: gestionnaire_id, procedure_id: procedure_id).pluck(:id) }

    duplicate_ids.each do |ids|
      ids.pop
      AssignTo.where(id: ids).destroy_all
    end
  end
end
