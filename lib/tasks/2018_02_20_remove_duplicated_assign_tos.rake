namespace :'2018_02_20_remove_duplicated_assign_tos' do
  task remove: :environment do
    duplicates = AssignTo.group(:gestionnaire_id, :procedure_id)
      .having("COUNT(*) > 1")
      .size
      .to_a

    duplicates.each do |duplicate|
      keys = duplicate.first
      gestionnaire_id = keys.first
      procedure_id = keys.last
      assign_tos = AssignTo.where(gestionnaire_id: gestionnaire_id, procedure_id: procedure_id).to_a
      assign_tos.shift
      assign_tos.each(&:destroy)
    end
  end
end
